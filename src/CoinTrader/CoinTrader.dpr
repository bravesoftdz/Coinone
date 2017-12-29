program CoinTrader;

uses
  Vcl.Forms,
  _fmMain in 'View\_fmMain.pas' {fmMain},
  Core in 'Core\Core.pas',
  ctGlobal in 'Global\ctGlobal.pas',
  ctOption in 'Global\ctOption.pas',
  Coinone in '..\common\Coinone.pas',
  Common in '..\common\Common.pas';

{$R *.res}

begin
  {
    // �ߺ� ������ �������� Ȱ��ȭ �Ͻÿ�.
    if not JclAppInstances.CheckInstance(1) then
    begin
    MessageBox(0, '���α׷��� �̹� �������Դϴ�.', 'Ȯ��', MB_ICONEXCLAMATION);
    JclAppInstances.SwitchTo(0);
    JclAppInstances.KillInstance;
    end;
  }

  Application.Initialize;
  Application.Title := APPLICATION_TITLE;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.
