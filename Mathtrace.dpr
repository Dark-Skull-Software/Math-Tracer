program MathTrace;

uses
  Forms,
  unitprinc in 'unitprinc.pas' {FormPrinc},
  DSObjParser in 'DSObjParser.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'mathtrace';
  Application.CreateForm(TFormPrinc, FormPrinc);
  Application.Run;
end.
