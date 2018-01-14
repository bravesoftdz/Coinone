unit cdOption;

interface

uses
  Classes, SysUtils, cdGlobal, System.IniFiles, Registry, Winapi.Windows, JdcGlobal;

type
  TOption = class
  private
    FIniFile: TCustomIniFile;
    constructor Create;
  private
    function GetDBInfo: String;
    procedure SetDBInfo(ADBInfo: String);
    function GetTcpPort: Integer;
    procedure SetTcpPort(const Value: Integer);
    procedure SetHttpPort(const Value: Integer);
    function GetHttpPort: Integer;
    function GetUseCloudLog: boolean;
    procedure SetUseCloudLog(const Value: boolean);
    function GetAccessToken: string;
    function GetSecretKey: string;
  public
    class function Obj: TOption;

    destructor Destroy; override;

    property TcpPort: Integer read GetTcpPort write SetTcpPort;
    property HttpPort: Integer read GetHttpPort write SetHttpPort;
    property DBInfo: String read GetDBInfo write SetDBInfo;
    property UseCloudLog: boolean read GetUseCloudLog write SetUseCloudLog;

    property AccessToken: string read GetAccessToken;
    property SecretKey: string read GetSecretKey;
  end;

implementation

var
  MyObj: TOption = nil;

  { TOption }

constructor TOption.Create;
var
  FileName: string;
begin
  // IniFile...
  FileName := ChangeFileExt(TGlobal.Obj.ExeName, '.ini');
  FIniFile := TIniFile.Create(FileName);

  // FIniFile := TMemIniFile.Create(FileName);

  // Registry...
  // FileName:= ''SOFTWARE\PlayIoT\' + PROJECT_CODE;
  // FIniFile := TRegistryIniFile.Create(FileName);
  // TRegistryIniFile(FIniFile).RegIniFile.RootKey := HKEY_CURRENT_USER;
end;

destructor TOption.Destroy;
begin
  if Assigned(FIniFile) then
    FIniFile.Free;

  inherited;
end;

function TOption.GetAccessToken: string;
begin
  result := FIniFile.ReadString('Auth', 'AccessToken', '');
end;

function TOption.GetDBInfo: String;
begin
  // Server=db.playiot.biz,DataBase=mydb,User_Name=playiot,Password=playiot,Port=5432
  result := FIniFile.ReadString('DB', 'Params', 'Edit DB connect params...');
end;

function TOption.GetTcpPort: Integer;
begin
  result := FIniFile.ReadInteger('DSServer', 'TCPPort', 211);
end;

function TOption.GetUseCloudLog: boolean;
begin
  result := FIniFile.ReadBool('Config', 'UseCloudLog', True);
end;

function TOption.GetHttpPort: Integer;
begin
  result := FIniFile.ReadInteger('DSServer', 'HTTPPort', 80);
end;

function TOption.GetSecretKey: string;
begin
  result := FIniFile.ReadString('Auth', 'SecretKey', '');
end;

procedure TOption.SetDBInfo(ADBInfo: String);
begin
  FIniFile.WriteString('DB', 'Params', ADBInfo);
end;

procedure TOption.SetTcpPort(const Value: Integer);
begin
  FIniFile.WriteInteger('DSServer', 'TCPPort', Value);
end;

procedure TOption.SetUseCloudLog(const Value: boolean);
begin
  FIniFile.WriteBool('Config', 'UseCloudLog', Value);
end;

procedure TOption.SetHttpPort(const Value: Integer);
begin
  FIniFile.WriteInteger('DSServer', 'HTTPPort', Value);
end;

class function TOption.Obj: TOption;
begin
  if MyObj = nil then
  begin
    MyObj := TOption.Create;
  end;
  result := MyObj;
end;

end.
