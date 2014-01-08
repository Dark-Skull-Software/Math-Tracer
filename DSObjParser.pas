unit DSObjParser;

interface

uses
  SysUtils, Math;

type
  TOperator = (opAdd, opDel, opMulti, opDiv, opPower, opSin,
               opCos, opTan, opLn, opExp, opLog, opNone);

const
  Operators = ['+', '-', '*', '/', '^', '�', '(', ')'];
  NoRight = [opSin, opCos, opTan, opExp, opLog, opLn];
  Digits = ['0'..'9', '.', ','];

type
  TNodeParser = class(TObject)
  private
    FValue:     extended;
    FOperator:  TOperator;
    FLeftNode:  TNodeParser;
    FRightNode: TNodeParser;
    function FindClosingBracket(Expr: string; pos: integer): integer;
    function FindLowerOperator(Expr: string): integer;
    function FindOperator(Expr: string; Operator: string): integer;
    function FloatToString(Value: Extended): string;
    function InsideBrackets(Expr: string; Pos: integer): boolean;
    function IsValidExpression(Expr: string): boolean;
    procedure LookForExponential(var Expr: string);
    procedure LookForPi(var Expr: string);
    procedure LookForPower2(var Expr: string);
    procedure MakeTree(Expr: string; var Erreur: boolean);
    procedure FreeAll;
  public
    constructor Create(Expression: string; var Erreur: boolean);
    destructor Destroy; override;
    function EvalNode(var Erreur: boolean): extended;
  published
    property Value:     extended    read FValue     write FValue;
    property Operator:  TOperator   read FOperator  write FOperator;
    property LeftNode:  TNodeParser read FLeftNode  write FLeftNode;
    property RightNode: TNodeParser read FRightNode write FRightNode;
  end;

implementation

function TNodeParser.InsideBrackets(Expr: string; Pos: integer): boolean;
var
  i: integer;
  Count: integer;
begin
  // Teste si on est au coeur de parenth�ses
  Count := 0;
  // On parcourt la chaine � la recherche de parenth�ses,
  // et si on en trouve on modifie le compteur:
  // Si une parenth�se est ouverte, on l'augmente.
  // Si une parenth�se est ferm�e, on le diminue
  // Si � la fin le compteur est �gal � 0, c'est qu'on
  // est en dehors de parenth�ses.
  for i := 1 to Pos do
    begin
      if Expr[i] = '(' then Count := Count + 1;
      if Expr[i] = ')' then Count := Count - 1;
    end;
  Result := not (Count = 0);
end;

function TNodeParser.FloatToString(Value: Extended): string;
var
  Buffer: array[0..$FE] of Char;
begin
  SetString(Result, Buffer, FloatToText(Buffer,
    Value, fvExtended, ffGeneral, $FF, $FF));
end;

function TNodeParser.IsValidExpression(Expr: string): boolean;
var
  i: integer;
  Count: integer;
begin
  // On teste si les caract�res tels que les parenth�ses, etc,
  // sont pr�sents en nb correct et dans le bon ordre
  Result := true;
  if Expr = '' then Exit;
  Count := 0;
  for i := 1 to Length(Expr) do
    begin
      if Expr[i] = '(' then Inc(Count);
      if Expr[i] = ')' then Dec(Count);
      if Count < 0 then
        begin
          Result := false;
          Exit;
        end;
    end;
  Result := (Count = 0);
end;

procedure TNodeParser.LookForExponential(var Expr: string);
var
  a: integer;
begin
  // Recherche des exponentielles sous la forme "e"
  // et remplacement par leur valeur
  repeat
    a := pos('e', Expr);
    if a = 0 then Exit;
    if Expr[a + 1] = 'x' then exit;
    Delete(Expr, a, 1);
    // On regarde si il y a des op�rateurs avant ou apr�s
    // Dans le cas contraire, on y ajoute un signe "*"
    // Avant
    if (a > 1) and (not (Expr[a - 1] in Operators)) then
      begin
        Insert('*', Expr, a);
        a := a + 1;
      end;
    // Apr�s
    if (a <= Length(Expr)) and (not (Expr[a] in Operators)) then
      begin
        Insert('*', Expr, a);
      end;
    // On ins�re la valeur de e
    Insert(FloatToString(Exp(1)), Expr, a);
  until a = 0;
end;

procedure TNodeParser.LookForPi(var Expr: string);
var
  a: integer;
begin
  // Recherche de "pi" et remplacement par sa valeur
  repeat
    a := pos('pi', Expr);
    if a = 0 then Exit;
    Delete(Expr, a, 2);
    // On regarde si il y a des op�rateurs avant ou apr�s
    // Dans le cas contraire, on y ajoute un signe "*"
    // Avant
    if (a > 1) and (not (Expr[a - 1] in Operators)) then
      begin
        Insert('*', Expr, a);
        a := a + 1;
      end;
    // Apr�s
    if (a <= Length(Expr)) and (not (Expr[a] in Operators)) then
      begin
        Insert('*', Expr, a);
      end;
    // On ins�re la valeur de pi
    Insert(FloatToString(pi), Expr, a);
  until a = 0;
end;

procedure TNodeParser.LookForPower2(var Expr: string);
var
  a: integer;
begin
  // Recherche du symbole "puissance 2" ("�")
  // et remplacement par "^2"
  repeat
    a := pos('�', Expr);
    if a = 0 then Exit;
    Delete(Expr, a, 1);
    // On v�rifie qu'il y a un nombre avant
    // Sinon, on ignore le caract�re
    if a = 1 then Exit;
    if (a > 1) and (not (Expr[a - 1] in Digits)) then Exit;
    // Si il y a des nombres apr�s, on ins�re un "*"
    if (a <= Length(Expr)) and (not (Expr[a] in Operators)) then
      begin
        Insert('*', Expr, a);
      end;
    // On ins�re "^2"
    Insert('^2', Expr, a);
  until a = 0;
end;

function TNodeParser.FindLowerOperator(Expr: string): integer;
begin
  // On trouve l'op�rateur avec la plus basse priorit�
  // le plus bas est le "+", le plus �lev�, les parenth�ses
  // Le moins doit �tre sup�rieur � 1, sinon une expression
  // de type -4 + 3 causera une erreur; il faut �galement
  // qu'il ne soit pr�c�d� d'aucun signe.
  // Pour chaque expression, on doit v�rifier qu'il ne se trouve
  // pas entre parenth�ses.
  Result := FindOperator(Expr, '+'); if (Result > 0) then exit;
  Result := FindOperator(Expr, '-');
  if (Result > 1) and (not (Expr[Result - 1] in Operators)) then Exit;
  Result := FindOperator(Expr, '*'); if (Result > 0) then exit;
  Result := FindOperator(Expr, '/'); if (Result > 0) then exit;
  Result := FindOperator(Expr, '^'); if (Result > 0) then exit;
  Result := FindOperator(Expr, 'sin'); if (Result > 0) then exit;
  Result := FindOperator(Expr, 'cos'); if (Result > 0) then exit;
  Result := FindOperator(Expr, 'tan'); if (Result > 0) then exit;
  Result := FindOperator(Expr, 'ln');  if (Result > 0) then exit;
  Result := FindOperator(Expr, 'log'); if (Result > 0) then exit;
  Result := FindOperator(Expr, 'exp'); if (Result > 0) then exit;
  // Si on n'a pas trouv� d'op�rateur en dehors des parenth�ses,
  // alors on effectue une recherche de parenth�ses...
  Result := Pos('(', Expr);
end;

function TNodeParser.FindClosingBracket(Expr: string; pos: integer): integer;
var
  i: integer;
  count: integer;
  bpos: integer;
begin
  // On recherche la position de la parenth�se fermante
  // de la parenth�se � la position pos de l'expression
  count := 0;
  bpos := 0;
  for i := pos to Length(Expr) do
    begin
      if Expr[i] = '(' then Count := Count + 1;
      if Expr[i] = ')' then Count := Count - 1;
      // Si le compteur est nul, c'est que la parenth�se
      // est ferm�e: on a trouv� la parenth�se fermante
      if Count = 0 then
        begin
          bpos := i;
          break;
        end;
    end;
  Result := bpos;
end;

function TNodeParser.FindOperator(Expr: string; Operator: string): integer;
var
  i: word;
  b: integer;
  Position: integer;
begin
  // Trouver la position de l'op�rateur
  Position := 0;
  repeat
    // On recherche la position de l'op�rateur
    Result := Pos(Operator, Expr);
    if Operator = '-' then
      begin
        // Si l'op�rateur est le "moins", on doit compter � partir du 2�
        // caract�re, sous peine de provoquer une boucle infinie:
        // Si on a par exemple "-2", il essaiera de calculer "0 - 2"
        // ind�finiment, sans issue possible
        Result := Pos(Operator, Copy(Expr, 2, Length(Expr) - 1)) + 1;
      end;
    // S'il n'existe pas dans la chaine, c'est r�gl�
    if Result = 0 then Exit;
    // Si la chaine est vide, c'est r�gl� aussi
    if Expr = '' then Exit;
    // S'il est entre parenth�ses, il faut recommencer
    // avec la chaine priv�e de l'expression entre
    // parenth�ses
    if InsideBrackets(Expr, Result) then
      begin
        b := 0;
        for i := 1 to Result do
          begin
            if Expr[i] = '(' then
              begin
                b := i;
                Break;
              end;
          end;
        Position := Position + FindClosingBracket(Expr, b);
        // On coupe la chaine pour n'avoir aucun pb avec la fonction
        // Pos, qui renvoie le premier caract�re trouv�:
        // si on a "(1+2)-5+6", il faut supprimer la premi�re partie
        // entre parenth�ses pour que Pos renvoie la postion du
        // dernier "+"
        Delete(Expr, 1, Position + 1);
      end
    else
      begin
        // Si il est en dehors des parenth�ses, c'est qu'on
        // a trouv� le bon op�rateur
        Result := Result + Position;
        Exit;
      end;
  until Result = 0;
end;

constructor TNodeParser.Create(Expression: string; var Erreur: boolean);
var
  Expr: string;
begin
  inherited Create;
  Value     := 0;
  LeftNode  := nil;
  RightNode := nil;
  Operator  := opNone;

  Expr := LowerCase(Expression);
  if Expr[1] = '+' then Delete(Expr, 1, 1);
  Erreur := true;
  if Expr = '' then Exit;
  if not IsValidExpression(Expr) then Exit;

  // Maintenant, on remplace les caract�res sp�ciaux
  LookForExponential(Expr);
  LookForPi(Expr);
  LookForPower2(Expr);

  // On cr�e l'arbre
  MakeTree(Expr, Erreur);

  // On analyse l'arbre
  Erreur := false;
  Value := EvalNode(Erreur);
end;

procedure TNodeParser.MakeTree(Expr: string; var Erreur: boolean);
var
  k: integer;
begin
  // Si l'expression est vide, on lui donne la valeur '0', pour
  // �viter une erreur de StrToFloat
  // puis on cherche l'op�rateur de plus faible priorit�
  if Expr = '' then Expr := '0';
  k := FindLowerOperator(Expr);

  // S'il n'y a pas d'op�rateur, c'est que c'est une valeur
  if k = 0 then
    begin
      Value := StrToFloat(Expr);
      Exit;
    end;

  // Si l'op�rateur est une parenth�se, alors on analyse
  // le contenu des parenth�ses
  if Expr[k] = '(' then
    begin
      Expr := Copy(Expr, k + 1, FindClosingBracket(Expr, k) - k - 1);
      MakeTree(Expr, Erreur);
      Exit;
    end;

  // Sinon, on analyse l'op�rateur
  case Expr[k] of
    '+': Operator := opAdd;
    '-': Operator := opDel;
    '/': Operator := opDiv;
    '*': Operator := opMulti;
    '^': Operator := opPower;
    's': Operator := opSin;
    'c': Operator := opCos;
    't': Operator := opTan;
    'e': Operator := opExp;
    'l': begin
           if Copy(Expr, k, 2) = 'ln' then Operator := opLn
           else Operator := opLog;
         end;
//    else MessageDlg(Expr + ' <> ' + Expr[k], mtInformation, [mbOk], 0);
  end;

  // On initialise le noeud � gauche
  case Operator of
    opSin, opCos, opTan, opLog, opExp: begin
                                         LeftNode := TNodeParser.Create(Copy(Expr, k + 4, Length(Expr) - FindClosingBracket(Expr, k + 4)), Erreur);
                                       end;
    opLn:                              begin
                                         LeftNode := TNodeParser.Create(Copy(Expr, k + 3, Length(Expr) - FindClosingBracket(Expr, k + 3)), Erreur);
                                       end;
    else
      begin
        // on initialise le noeud � droite uniquement pour
        // les op�rateurs simple: +, -, *, /, ^
        // On remplit les noeuds de mani�re r�cursive
        LeftNode  := TNodeParser.Create(Copy(Expr, 1, k - 1), Erreur);
        RightNode := TNodeParser.Create(Copy(Expr, k + 1, Length(Expr) - k), Erreur);
      end;
  end;
end;

function TNodeParser.EvalNode(var Erreur: boolean): extended;
var
  T1, T2: extended;
begin
  // On �value un noeud...
  // Si il n'y a pas d'enfant, alors le r�sultat est la valeur
  Result := 0;
  if Erreur then Exit;
  if Operator = opNone then
    begin
      // Si il n'y a pas d'op�rateur, c'est que le noeud
      // est une valeur. On lib�re la m�moire allou�e au noeud
      Result := Value;
    end
  else
    // Sinon, on calcule les enfants
    begin
      // le noeud � gauche
      T1 := LeftNode.EvalNode(Erreur);
      // le noeud � droite, si il y a besoin
      if (Operator in noRight) then T2 := 0
      else T2 := RightNode.EvalNode(Erreur);
      if Erreur then exit;
      // on applique l'op�rateur
      case Operator of
        opAdd:   Result := T1 + T2;
        opDel:   Result := T1 - T2;
        opDiv:   begin
                   // Attention aux divisions par z�ro
                   if T2 = 0 then begin Erreur := true; exit; end
                   else Result := T1 / T2;
                 end;
        opMulti: Result := T1 * T2;
        opPower: begin
                   // 0 ne peut �tre �lev� � une puissance
                   if (T1 = 0) then begin Erreur := true; exit; end
                   else Result := Power(T1, T2);
                 end;
        // Les fonctions suivantes n'op�rent
        // que sur le noeud � gauche
        opCos:   Result := Cos(T1);
        opSin:   Result := Sin(T1);
        opTan:   Result := Tan(T1);
        opLn:    begin
                   // Ln n'accepte que des param�tres positifs
                   if T1 <= 0 then begin Erreur := true; Exit; end
                   else Result := Ln(T1);
                 end;
        opExp:   Result := Exp(T1);
        opLog:   begin
                   // Log n'accepte que des param�tres positifs
                   if T1 <= 0 then begin Erreur := true; Exit; end
                   else Result := Log10(T1);
                 end;
      end;
    end;
end;

procedure TNodeParser.FreeAll;
begin
  if Assigned(LeftNode)  then
    begin
      LeftNode.FreeAll;
      LeftNode.Free;
      LeftNode := nil;
    end;
  if Assigned(RightNode) then
    begin
      RightNode.FreeAll;
      RightNode.Free;
      RightNode := nil;
    end;
end;

destructor TNodeParser.Destroy;
begin
  FreeAll;
  inherited Destroy;
end;

end.
