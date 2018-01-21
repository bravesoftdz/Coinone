program CoinTrader;

uses
  Vcl.Forms,
  _fmMain in 'View\_fmMain.pas' {fmMain},
  Core in 'Core\Core.pas',
  ctGlobal in 'Global\ctGlobal.pas',
  ctOption in 'Global\ctOption.pas',
  Common in '..\common\Common.pas',
  _dmDataProvider in 'Core\_dmDataProvider.pas' {dmDataProvider: TDataModule},
  ClientClassesUnit in 'Global\ClientClassesUnit.pas';

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
  Application.CreateForm(TdmDataProvider, dmDataProvider);
  Application.Run;

end.
