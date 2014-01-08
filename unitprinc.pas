unit unitprinc;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Buttons, registry, DSObjParser;

const
  ErrString = 'Erreur';

type
  TFormPrinc = class(TForm)
    PageControl: TPageControl;
    Panel: TPanel;
    ButtonTrace: TButton;
    TabSheetCurve: TTabSheet;
    PaintBox: TPaintBox;
    TabSheetTable: TTabSheet;
    ValueTable: TListView;
    GroupBox: TGroupBox;
    FuncEdit: TEdit;
    Labelx: TLabel;
    TabSheetLimites: TTabSheet;
    EditXMin: TEdit;
    LabelXmin: TLabel;
    EditXmax: TEdit;
    LabelXmax: TLabel;
    LabelXstep: TLabel;
    EditXstep: TEdit;
    Bevel1: TBevel;
    LabelYmin: TLabel;
    LabelYmax: TLabel;
    LabelYstep: TLabel;
    EditYMin: TEdit;
    EditYMax: TEdit;
    EditYStep: TEdit;
    TabSheetOptions: TTabSheet;
    PaintBox1: TPaintBox;
    PaintBox2: TPaintBox;
    PaintBox3: TPaintBox;
    PaintBox4: TPaintBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Colorb1: TBitBtn;
    colorb2: TBitBtn;
    colorb3: TBitBtn;
    colorb4: TBitBtn;
    ColorDialog: TColorDialog;
    ButtonDefaultSize: TButton;
    ButtonDefaultColors: TButton;
    Colorb5: TBitBtn;
    PaintBox5: TPaintBox;
    Label5: TLabel;
    procedure PaintBoxPaint(Sender: TObject);
    procedure ButtonTraceClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure PaintBox2Paint(Sender: TObject);
    procedure PaintBox3Paint(Sender: TObject);
    procedure PaintBox4Paint(Sender: TObject);
    procedure Colorb1Click(Sender: TObject);
    procedure colorb2Click(Sender: TObject);
    procedure colorb3Click(Sender: TObject);
    procedure colorb4Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonDefaultSizeClick(Sender: TObject);
    procedure ButtonDefaultColorsClick(Sender: TObject);
    procedure PaintBox5Paint(Sender: TObject);
    procedure Colorb5Click(Sender: TObject);
  private
    { Déclarations privées }
    Xmin,Xmax,Xstep,Ymin,Ymax,Ystep:extended;
    Xcstep,Ycstep:extended;
    Xorig,Yorig:extended;
    Color1,color2,Color3,Color4,color5:integer;
    registre:Tregistry;
  public
    { Déclarations publiques }
    procedure ClearPaintBox;
    procedure DrawGrid;
    procedure DrawLines;
    procedure ReplaceUnknown;
    procedure ReadRegistry;
    procedure WriteRegistry;
  end;

var
  FormPrinc: TFormPrinc;
  formule, oldcal: string;
  Value, xcoord: extended;
  i, Err: Integer;

implementation

{$R *.DFM}

procedure TFormPrinc.ClearPaintBox;
begin
  // On efface le contenu de la PaintBox en la remplissant
  // avec la couleur de fond
  PaintBox.Canvas.Brush.Color := color1;
  PaintBox.Canvas.Rectangle(0, 0, PaintBox.Width, PaintBox.Height);
end;

procedure TFormPrinc.DrawGrid;
var
  i: integer;
begin
  // On dessine la grille
  // XStep et YStep correspondent aux pas définis dans
  // la fiche de configuration
  // XCStep et YCStep correspondent aux nombres de lignes à afficher
  XCstep := PaintBox.Width / (abs(Xmin) + abs(Xmax)) * xstep;
  YCStep := PaintBox.Height / (abs(Ymin) + abs(Ymax)) * ystep;
  // Xorig et YOrig déterminent la position de l'origine
  // par rapport à la PaintBox
  Xorig := Xmin / xstep * xcstep * (-1);
  Yorig := PaintBox.height - (Ymin / ystep * ycstep * (-1));

  // On définit la couleur de la grille par défaut
  PaintBox.Canvas.Pen.Color := color2;
  // On trace les lignes verticales
  // 1) de 0 à - <limite du tableau>
  For i := 1 to round(xorig / xcstep) do
    begin
      Paintbox.Canvas.MoveTo(round(Xorig - i * xcstep), 0);
      Paintbox.Canvas.LineTo(round(Xorig - i * xcstep), PaintBox.Height - 1);
    end;
  // 2) de 0 à + <limite du tableau>
  For i := 1 to round((Paintbox.Width - xorig) / xcstep) do
    begin
      Paintbox.Canvas.MoveTo(round(Xorig + i * xcstep), 0);
      Paintbox.Canvas.LineTo(round(Xorig + i * xcstep), PaintBox.Height - 1);
    end;
  // Les lignes horizontales
  // 1) de 0 à - <limite du tableau>
  For i := 1 to round(yorig / ycstep) do
    begin
      Paintbox.Canvas.MoveTo(0, round(yorig - i * ycstep));
      Paintbox.Canvas.LineTo(Paintbox.Width - 1, round(yorig - i * ycstep));
    end;
  // 2) de 0 à + <limite du tableau>
  For i := 1 to round((PaintBox.Height - yorig) / ycstep) do
    begin
      Paintbox.Canvas.MoveTo(0,round(yorig + i*ycstep));
      Paintbox.Canvas.LineTo(Paintbox.width-1,round(yorig + i*ycstep));
    end;

  // On définit la couleur de l'origine par défautt
  PaintBox.Canvas.Pen.Color := color3;

  // On trace l'origine verticale
  If Xmin < 0 then
    begin
      PaintBox.Canvas.MoveTo(round(xorig), 0);
      PaintBox.Canvas.LineTo(round(xorig), PaintBox.Height);
    end;
  // On trace l'origine horizontale
  If Ymin < 0 then
    begin
      PaintBox.Canvas.MoveTo(0, round(yorig));
      PaintBox.Canvas.LineTo(PaintBox.Width, round(yorig));
    end;
end;

procedure TFormPrinc.PaintBoxPaint(Sender: TObject);
begin
  // On efface la paintBox
  ClearPaintBox;
  // On dessine la grille
  DrawGrid;
  // On vérife que les calculs ont déjà été effectués
  // avant de tracer les lignes
  If (OldCal = FuncEdit.Text)
  and (ValueTable.Items.Count > 0) then DrawLines;
end;

procedure TFormPrinc.ReplaceUnknown;
var
  j: integer;
  tp: string;
  count: integer;
begin
  // On remplace le x par la valeur en cours
  count := 0;
  Tp := LowerCase(Formule);
  repeat
    j := Pos('x', Tp);
    if (j > 0) then
      begin
        if (j > 1) and (Tp[j - 1] = 'e') and (j < Length(Tp)) and (Tp[j + 1] = 'p') then
          begin
            Count := count + j;
            Delete(Tp, 1, j);
          end
        else
          begin
            Delete(tp, j, 1);
            Delete(formule, j + count, 1);
            // S'il n'y a pas d'opérateur, on insère un "*" avant
            if (j > 1) and (not (tp[j - 1] in Operators)) then
              begin
                Insert('*', tp, j);
                Insert('*', formule, j + count);
                j := j + 1;
              end;
            // et après aussi...
            if (j <= Length(Tp)) and (not (Tp[j] in Operators)) then
              begin
                Insert('*', Tp, j);
                Insert('*', formule, j + count);
              end;
            Insert(FloatToStr(xcoord), tp, j);
            Insert(FloatToStr(xcoord), formule, j + count);
          end;
      end;
  until j = 0;
end;

procedure TFormPrinc.ButtonTraceClick(Sender: TObject);
var
  N: TNodeParser;
  Erreur: boolean;
  j:integer;
begin
  // On demande le tracé de la fonction
  // Si la fonction est vide, ca ne sert à rien de continuer
  If FuncEdit.Text <> '' then
    begin
      // On efface le tableau de valeurs
      Valuetable.Items.Clear;
      // On stocke la fonction dans OldCal
      OldCal := FuncEdit.Text;
      for j := 0 to PaintBox.Width do
        begin
          // Pour chaque pixel horizontal de la paintbox
          // 1) On calcule les coordonnées
          xcoord := j * (abs(xmin) + abs(xmax)) / PaintBox.Width;
          xcoord := xcoord + xmin;
          // 2) On insére la valeur de "X"
          formule := FuncEdit.Text;
          ReplaceUnknown;

          // On ajoute la valeur de "X" dans le tableau
          ValueTable.Items.Add;
          ValueTable.Items[j].Caption := FloatToStr(xcoord);

          // On calcule la fonction pour la valeur de X
          N := TNodeParser.Create(Formule, Erreur);
          Value := N.Value;
          N.Free;
          // S'il n'y a pas d'erreur, alors on insère la valeur de Y
          // dans le tableau, sinon, on ajoute la chaine ErrString,
          // définie en début d'unité
          if Erreur then ValueTable.Items[j].SubItems.Add(ErrString)
          else ValueTable.Items[j].SubItems.Add(FloatToStr(value));
        end;
      // On trace la fonction
      FormPrinc.PaintBoxPaint(self);
    end
  else
    begin
      // Sinon on efface le tableau de valeurs
      ValueTable.Items.Clear;
      FormPrinc.PaintBoxPaint(self);
    end;
end;

procedure TFormprinc.DrawLines;
var
  j: integer;
  x1, y1: integer;
  b1, b2: boolean;
begin
  // On trace les lignes
  If (Valuetable.Items[0].Subitems.Strings[0] = ErrString) then
    begin
      // Si le résultat est une erreur, alors on place un point
      // de couleur exception sur l'origine
      x1 := 0;
      y1 := round(yorig);
      PaintBox.Canvas.Pixels[x1, y1] := color5;
    end;
  for j := 1 to Pred(ValueTable.Items.Count) do
    begin
      // Pour chaque élément...
      If (Valuetable.Items[j].Subitems.Strings[0] = ErrString) then
        begin
          // Si le résultat est une erreur, alors on place un point
          // de couleur exception sur l'origine
          x1 := round(xorig + xcstep / xstep * StrToFloat(ValueTable.Items[j].Caption));
          y1 := round(yorig);
          PaintBox.Canvas.Pixels[x1, y1] := color5;
        end
      else
        begin
          // Sinon
          if (ValueTable.Items[j - 1].SubItems.Strings[0] = ErrString) then
            begin
              // Si le résultat précédent est une erreur, alors on place un point
              x1 := round(xorig + xcstep / xstep * StrToFloat(ValueTable.Items[j].Caption));
              y1 := round(yorig - ycstep / ystep * StrTofloat(Valuetable.Items[j].SubItems.Strings[0]));
              if (y1 > 0) and (y1 < PaintBox.Height) then PaintBox.Canvas.Pixels[x1, y1] := color4;
            end
          else
            begin
              // Sinon, on trace la ligne avec le point précédent
              PaintBox.Canvas.Pen.Color := Color4;
              x1 := round(xorig + xcstep /xstep* StrToFloat(ValueTable.Items[j-1].Caption));
              y1 := round(yorig - ycstep /ystep* StrTofloat(Valuetable.Items[j-1].SubItems.Strings[0]));
              b1 := (y1 < 0) or (y1 > PaintBox.Height);
              PaintBox.Canvas.MoveTo(x1, y1);
              x1 := round(xorig + xcstep /xstep* StrToFloat(ValueTable.Items[j].Caption));
              y1 := round(yorig - ycstep /ystep* StrTofloat(Valuetable.Items[j].SubItems.Strings[0]));
              b2 := (y1 < 0) or (y1 > PaintBox.Height);
              if not (b1 and b2) then PaintBox.Canvas.LineTo(x1, y1);              
            end
        end;
    end;
end;

procedure TFormPrinc.FormCreate(Sender: TObject);
begin
  // On force le séparateur décimal à être le '.'
  Decimalseparator := '.';
  // On lit les options dans la base de registre
  ReadRegistry;
  // On oblige la page de courbe à étre affichée
  PageControl.ActivePage := TabSheetCurve;
end;

procedure TFormPrinc.EditExit(Sender: TObject);
begin
  // Si on quitte un TEdit, on stocke les valeurs
  // dans les variables globales
  XMin := StrTofloat(EditXmin.Text);
  Xmax := StrTofloat(EditXmax.Text);
  Xstep := StrTofloat(EditXstep.Text);
  Ymin := StrTofloat(EditYmin.Text);
  Ymax := StrTofloat(EditYmax.Text);
  Ystep := StrTofloat(EditYstep.Text);
end;

procedure TFormPrinc.PaintBox1Paint(Sender: TObject);
begin
  // On trace la couleur dans les boutons de choix de couleur
  PaintBox1.Canvas.brush.Color := Color1;
  Paintbox1.Canvas.Rectangle(0,0, 57, 25);
end;

procedure TFormPrinc.PaintBox2Paint(Sender: TObject);
begin
  // On trace la couleur dans les boutons de choix de couleur
  PaintBox2.Canvas.Brush.Color := color2;
  Paintbox2.Canvas.Rectangle(0, 0, 57, 25);
end;

procedure TFormPrinc.PaintBox3Paint(Sender: TObject);
begin
  // On trace la couleur dans les boutons de choix de couleur
  PaintBox3.Canvas.Brush.Color := color3;
  Paintbox3.Canvas.Rectangle(0,0, 57, 25);
end;

procedure TFormPrinc.PaintBox4Paint(Sender: TObject);
begin
  // On trace la couleur dans les boutons de choix de couleur
  PaintBox4.Canvas.Brush.Color := color4;
  Paintbox4.Canvas.Rectangle(0,0, 57, 25);
end;

procedure TFormPrinc.PaintBox5Paint(Sender: TObject);
begin
  // On trace la couleur dans les boutons de choix de couleur
  PaintBox5.Canvas.Brush.Color := color5;
  Paintbox5.Canvas.Rectangle(0,0, 57, 25);
end;

procedure TFormPrinc.Colorb1Click(Sender: TObject);
begin
  // On change la couleur correspondant au bouton
  ColorDialog.Color := color1;
  If colorDialog.Execute then color1 := colordialog.Color;
  FormPrinc.PaintBox1Paint(self);
end;

procedure TFormPrinc.colorb2Click(Sender: TObject);
begin
  // On change la couleur correspondant au bouton
  ColorDialog.Color := color2;
  If colorDialog.Execute then color2 := colordialog.Color;
  FormPrinc.PaintBox2Paint(self);
end;

procedure TFormPrinc.colorb3Click(Sender: TObject);
begin
  // On change la couleur correspondant au bouton
  ColorDialog.Color := color3;
  If colorDialog.Execute then color3 := colordialog.Color;
  FormPrinc.PaintBox3Paint(self);
end;

procedure TFormPrinc.colorb4Click(Sender: TObject);
begin
  // On change la couleur correspondant au bouton
  ColorDialog.Color := color4;
  If colorDialog.Execute then color4 := colordialog.Color;
  FormPrinc.PaintBox4Paint(self);
end;

procedure TFormPrinc.Colorb5Click(Sender: TObject);
begin
  // On change la couleur correspondant au bouton
  ColorDialog.Color := color5;
  If colorDialog.Execute then color5 := colordialog.Color;
  FormPrinc.PaintBox5Paint(self);
end;

procedure TFormPrinc.ReadRegistry;
begin
  // On lit les options dans la base de registre, et on modifie
  // les composants en fonction
  Registre := TRegistry.Create;
  Registre.RootKey := HKEY_LOCAL_MACHINE;
  if Registre.OpenKey('\SoftWare\Laure Lécuyer\MathTrace',True) then
    begin
      // Les couleurs
      if Registre.ValueExists('Color1') then Color1 := Registre.ReadInteger('Color1')
      else Color1 := clBlack;
      if Registre.ValueExists('Color2') then Color2 := Registre.ReadInteger('Color2')
      else Color2 := $00606060;
      if Registre.ValueExists('Color3') then Color3 := Registre.ReadInteger('Color3')
      else Color3 := clWhite;
      if Registre.ValueExists('Color4') then Color4 := Registre.ReadInteger('Color4')
      else Color4 := clGreen;
      if Registre.ValueExists('Color5') then Color5 := Registre.ReadInteger('Color5')
      else Color5 := clRed;
      // Les coordonnées limites du tableau
      if Registre.ValueExists('XMin') then XMin := Registre.ReadFloat('XMin')
      else XMin := -10;
      if Registre.ValueExists('XMax') then XMax := Registre.ReadFloat('XMax')
      else XMax := 10;
      if Registre.ValueExists('YMin') then YMin := Registre.ReadFloat('YMin')
      else YMin := -10;
      if Registre.ValueExists('YMax') then YMax := Registre.ReadFloat('YMax')
      else YMax := 10;
      if Registre.ValueExists('XStep') then XStep := Registre.ReadFloat('XStep')
      else XStep := 1;
      if Registre.ValueExists('YStep') then YStep := Registre.ReadFloat('YStep')
      else YStep := 1;
      // L'équation
      if Registre.ValueExists('Equation') then FuncEdit.Text := Registre.ReadString('Equation')
      else FuncEdit.Text := 'x';
      // On définit le texte des TEDit
      EditXmin.Text := FloatToStr(Xmin);
      EditXmax.Text := FloatToStr(Xmax);
      EditXstep.Text := FloatToStr(XStep);
      EditYmin.Text := FloatToStr(Ymin);
      EditYmax.Text := FloatToStr(Ymax);
      EditYstep.Text := FloatToStr(Ystep);
    end;
  Registre.Free;
end;

procedure TFormPrinc.WriteRegistry;
begin
  // On sauvegarde les options
  Registre := TRegistry.Create;
  Registre.RootKey := HKEY_LOCAL_MACHINE;
  Registre.OpenKey('\SoftWare\Laure Lécuyer\MathTrace',True);
  Registre.WriteInteger('Color1', color1);
  Registre.WriteInteger('Color2', color2);
  Registre.WriteInteger('color3', color3);
  Registre.WriteInteger('Color4', color4);
  Registre.WriteInteger('Color5', color5);
  Registre.WriteFloat('Xmin', Xmin);
  Registre.WriteFloat('Xmax', Xmax);
  Registre.WriteFloat('XStep', Xstep);
  Registre.WriteFloat('Ymin', Ymin);
  Registre.WriteFloat('Ymax', Ymax);
  Registre.WriteFloat('Ystep', Ystep);
  Registre.WriteString('Equation', funcedit.Text);
  Registre.Free;
end;

procedure TFormPrinc.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  WriteRegistry;
end;

procedure TFormPrinc.ButtonDefaultSizeClick(Sender: TObject);
begin
  // On remet les coordonnées par défaut
  Xmin := -10;
  Xmax := 10;
  XStep := 1;
  Ymin := -10;
  YMax := 10;
  YStep := 1;
  EditXmin.Text := FloatToStr(Xmin);
  EditXmax.Text := FloatToStr(Xmax);
  EditXstep.Text := FloatToStr(XStep);
  EditYmin.Text := FloatToStr(Ymin);
  EditYmax.Text := FloattoStr(Ymax);
  EditYstep.Text := FloattoStr(Ystep);
  WriteRegistry;
end;

procedure TFormPrinc.ButtonDefaultColorsClick(Sender: tobject);
begin
  // On remet les couleurs par défaut
  Color1 := clBlack;
  Color2 := $00606060;
  Color3 := clWhite;
  Color4 := clGreen;
  Color5 := clRed;
  FormPrinc.PaintBox1Paint(self);
  FormPrinc.PaintBox2Paint(self);
  FormPrinc.PaintBox3Paint(self);
  FormPrinc.PaintBox4Paint(self);
  FormPrinc.PaintBox5Paint(self);
  WriteRegistry;
end;

end.
