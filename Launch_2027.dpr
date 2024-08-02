program Launch_2027;

uses
  Vcl.Forms,
  uFrmMain in 'uFrmMain.pas' {frmMain},
  Launch2027.consts in 'Launch2027.consts.pas',
  Launch2027.Classes in 'Launch2027.Classes.pas',
  Launch2027.Utils in 'Launch2027.Utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
