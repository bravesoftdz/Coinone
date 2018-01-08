unit _dmDataProvider;

interface

uses
  System.SysUtils, System.Classes, ClientClassesUnit, Data.DBXDataSnap, IPPeerClient,
  Data.DBXCommon, Data.DbxHTTPLayer, Data.DB, Data.SqlExpr, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, FireDAC.Comp.Client, Coinone, System.JSON,
  REST.JSON, JdcGlobal.ClassHelper, System.DateUtils, JdcGlobal.DSCommon,
  Datasnap.DSClientRest, FireDAC.Stan.StorageBin, System.Math, JdcView, JdcGlobal, ctGlobal,
  Data.SqlTimSt;

type
  TdmDataProvider = class(TDataModule)
    mtTick: TFDMemTable;
    mtTickvolume: TFloatField;
    mtTicklast: TFloatField;
    mtTickfirst: TFloatField;
    mtTickyesterday_volume: TFloatField;
    mtTickvolume_rate: TFloatField;
    mtTickprice_rate: TFloatField;
    mtTickcoin: TWideStringField;
    dsTick: TDataSource;
    mtTickyesterday_last: TFloatField;
    mtTickPeriod: TFDMemTable;
    WideStringField1: TWideStringField;
    FloatField1: TFloatField;
    FloatField3: TFloatField;
    FloatField4: TFloatField;
    FloatField6: TFloatField;
    DSRestConnection: TDSRestConnection;
    mtTickPeriodyesterday_last: TFloatField;
    mtTickPeriodprice_rate: TFloatField;
    mtTickPeriodtick_stamp: TSQLTimeStampField;
    FDStanStorageBinLink: TFDStanStorageBinLink;
    mtTickPeriodvolume_avg: TFloatField;
    mtHighLow: TFDMemTable;
    FloatField2: TFloatField;
    FloatField7: TFloatField;
    mtHighLowhigh_price: TFloatField;
    mtHighLowlow_price: TFloatField;
    mtTickPeriodstoch: TFloatField;
    mtTickhigh: TFloatField;
    mtTicklow_price: TFloatField;
    mtBalance: TFDMemTable;
    WideStringField2: TWideStringField;
    FloatField5: TFloatField;
    FloatField8: TFloatField;
    FloatField9: TFloatField;
    dsBalance: TDataSource;
    mtMyLimitOrder: TFDMemTable;
    FloatField10: TFloatField;
    FloatField11: TFloatField;
    mtMyLimitOrderorder_stamp: TSQLTimeStampField;
    mtMyLimitOrderorder_type: TWideStringField;
    msMylimitOrder: TDataSource;
    mtMyLimitOrderorder_id: TWideStringField;
    mtMyLimitOrdercoin: TWideStringField;
    procedure mtTickCalcFields(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure mtTickPeriodCalcFields(DataSet: TDataSet);
    procedure mtTickcoinGetText(Sender: TField; var Text: string; DisplayText: Boolean);
    procedure mtMyLimitOrderorder_typeGetText(Sender: TField; var Text: string;
      DisplayText: Boolean);
  private
    FInstanceOwner: Boolean;
    FsmDataProviderClient: TsmDataProviderClient;
    FsmDataLoaderClient: TsmDataLoaderClient;
    FYesterDayValue: double;

    function Order(APrice, ACount: double; ACoin: string; AType: TRequestType): TJSONObject;
    function CreateParams(ACoin: string; ABegin, AEnd: TDateTime): TJSONObject;
    function GetsmDataProviderClient: TsmDataProviderClient;
    function GetsmDataLoaderClient: TsmDataLoaderClient;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Tick;
    procedure ChartData;

    function Balance: Integer;

    function MarketAsk(Value: Integer): Boolean;
    function MarketBid(Value: Integer): Boolean;

    function LimitAsk(APrice, ACount: double): Boolean;
    function LimitBid(APrice, ACount: double): Boolean;

    procedure LimitOrder;
    procedure CancelOrder;

    property InstanceOwner: Boolean read FInstanceOwner write FInstanceOwner;
    property smDataProviderClient: TsmDataProviderClient read GetsmDataProviderClient
      write FsmDataProviderClient;
    property smDataLoaderClient: TsmDataLoaderClient read GetsmDataLoaderClient
      write FsmDataLoaderClient;

    property YesterDayValue: double read FYesterDayValue;
  end;

var
  dmDataProvider: TdmDataProvider;

implementation

{ %CLASSGROUP 'Vcl.Controls.TControl' }

{$R *.dfm}

function TdmDataProvider.MarketAsk(Value: Integer): Boolean;
var
  res: TJSONObject;
  Price, Count: double;
  CoinCode: string;
begin
  result := false;
  CoinCode := mtBalance.FieldByName('coin').AsString;
  if CoinCode = 'krw' then
    Exit;

  Balance;
  if Value > mtBalance.FieldByName('krw').AsFloat then
  begin
    TGlobal.Obj.ApplicationMessage(msError, '�ŵ�����', '�ֹ��ݾ� �ʰ� - ' + FormatFloat('#,##0',
      mtBalance.FieldByName('krw').AsFloat) + '��');
    Exit;
  end;

  Price := mtBalance.FieldByName('last').AsFloat;
  Count := Value / Price;
  res := Order(Price, Count, CoinCode, rtLimitSell);
  result := res.GetString('result') = 'success';

  if result then
    LimitOrder
  else
    TGlobal.Obj.ApplicationMessage(msError, 'MarketAsk', res.GetString('result'));
end;

function TdmDataProvider.Balance: Integer;
var
  JSONObject, _Balance: TJSONObject;

  I: Integer;
  BookMark: TBookmark;
  Amount, Price: double;
  KRW, Total: double;
begin
  result := 0;

  FYesterDayValue := smDataProviderClient.TotalValue(DateOf(IncDay(Now, -1)));

  Total := 0;

  Tick;
  JSONObject := smDataProviderClient.AccountInfo(Integer(rtBalance));
  BookMark := mtBalance.BookMark;
  mtBalance.DisableControls;
  try
    for I := Low(Coins) to High(Coins) do
    begin
      if mtTick.Locate('coin', Coins[I]) then
      begin
        Price := mtTick.FieldByName('last').AsFloat;
      end
      else
        Price := 1;

      if mtBalance.Locate('coin', Coins[I]) then
        mtBalance.Edit
      else
        mtBalance.Insert;

      _Balance := JSONObject.GetJSONObject(Coins[I]);

      Amount := _Balance.GetString('balance').ToDouble;
      KRW := Price * Amount;
      Total := Total + KRW;

      // KRW ���� �ܾ�
      if Coins[I] = 'krw' then
        result := _Balance.GetString('avail').ToInteger;

      mtBalance.FieldByName('coin').AsString := Coins[I];
      mtBalance.FieldByName('amount').AsFloat := Amount;

      mtBalance.FieldByName('last').AsFloat := Price;
      mtBalance.FieldByName('krw').AsFloat := KRW;
      mtBalance.CommitUpdates;
    end;
  finally
    mtBalance.EnableControls;
  end;

  if mtBalance.BookmarkValid(BookMark) then
    mtBalance.BookMark := BookMark;

  TView.Obj.sp_AsyncMessage('KrwValue', Total.ToString);
end;

function TdmDataProvider.MarketBid(Value: Integer): Boolean;
var
  res: TJSONObject;
  Price, Count: double;
  CoinCode: string;
  KRW: Integer;
begin
  result := false;
  CoinCode := mtBalance.FieldByName('coin').AsString;
  if CoinCode = 'krw' then
    Exit;

  KRW := Balance;
  if Value > KRW then
  begin
    TGlobal.Obj.ApplicationMessage(msError, '�ż�����', '�ֹ��ݾ� �ʰ� - ' + FormatFloat('#,##0',
      KRW) + '��');
    Exit;
  end;

  Price := mtBalance.FieldByName('last').AsFloat;
  Count := Value / Price;
  res := Order(Price, Count, CoinCode, rtLimitBuy);
  result := res.GetString('result') = 'success';

  if result then
    LimitOrder
  else
    TGlobal.Obj.ApplicationMessage(msError, 'MarketBid', res.GetString('result'));
end;

procedure TdmDataProvider.CancelOrder;
var
  res, Params: TJSONObject;
begin
  Params := TJSONObject.Create;
  Params.AddPair('order_id', mtMyLimitOrder.FieldByName('order_id').AsString);
  Params.AddPair('price', mtMyLimitOrder.FieldByName('price').AsString);
  Params.AddPair('qty', mtMyLimitOrder.FieldByName('amount').AsString);

  if mtMyLimitOrder.FieldByName('order_type').AsString = 'ask' then
    Params.AddPair('is_ask', '1')
  else
    Params.AddPair('is_ask', '0');

  Params.AddPair('currency', mtMyLimitOrder.FieldByName('coin').AsString);

  res := smDataProviderClient.Order(Integer(rtCancelOrder), Params);
  if res.GetString('result') = 'success' then
    LimitOrder
  else
    TGlobal.Obj.ApplicationMessage(msError, 'CancelOrder', res.GetString('result'));
end;

procedure TdmDataProvider.ChartData;
var
  Params: TJSONObject;
  Coin: String;
begin
  Coin := mtTick.FieldByName('coin').AsString;
  Params := CreateParams(Coin, IncDay(Now, -14), Now);
  mtHighLow.LoadFromDSStream(smDataProviderClient.HighLow(Params));

  Params := CreateParams(Coin, IncDay(Now, -2), Now);
  mtTickPeriod.LoadFromDSStream(smDataProviderClient.Tick(Params));
end;

constructor TdmDataProvider.Create(AOwner: TComponent);
begin
  inherited;
  FInstanceOwner := True;
  FYesterDayValue := 0;
end;

function TdmDataProvider.Order(APrice, ACount: double; ACoin: string; AType: TRequestType)
  : TJSONObject;
var
  Params: TJSONObject;
begin
  Params := TJSONObject.Create;
  Params.AddPair('price', Format('%.0f', [APrice]));
  Params.AddPair('qty', Format('%.2f', [ACount]));
  Params.AddPair('currency', ACoin);
  result := smDataProviderClient.Order(Integer(AType), Params);
end;

function TdmDataProvider.CreateParams(ACoin: string; ABegin, AEnd: TDateTime): TJSONObject;
begin
  result := TJSONObject.Create;
  result.AddPair('coin_code', UpperCase(ACoin));
  result.AddPair('begin_time', ABegin.ToISO8601);
  result.AddPair('end_time', AEnd.ToISO8601);
end;

procedure TdmDataProvider.DataModuleCreate(Sender: TObject);
begin
  mtTick.Open;
  mtBalance.Open;
end;

destructor TdmDataProvider.Destroy;
begin
  FsmDataProviderClient.Free;
  FsmDataLoaderClient.Free;
  inherited;
end;

function TdmDataProvider.GetsmDataProviderClient: TsmDataProviderClient;
begin
  if FsmDataProviderClient = nil then
    FsmDataProviderClient := TsmDataProviderClient.Create(DSRestConnection, FInstanceOwner);

  result := FsmDataProviderClient;
end;

function TdmDataProvider.LimitAsk(APrice, ACount: double): Boolean;
var
  res: TJSONObject;
  CoinCode: string;
begin
  result := false;
  CoinCode := mtBalance.FieldByName('coin').AsString;
  if CoinCode = 'krw' then
    Exit;

  Balance;
  if ACount > mtBalance.FieldByName('amount').AsFloat then
  begin
    TGlobal.Obj.ApplicationMessage(msError, '�ŵ�����', '�ֹ����� �ʰ� - ' + FormatFloat('#,##0.00',
      mtBalance.FieldByName('amount').AsFloat));
    Exit;
  end;

  res := Order(APrice, ACount, CoinCode, rtLimitSell);
  result := res.GetString('result') = 'success';

  if result then
    LimitOrder
  else
    TGlobal.Obj.ApplicationMessage(msError, 'LimitAsk', res.GetString('result'));
end;

function TdmDataProvider.LimitBid(APrice, ACount: double): Boolean;
var
  res: TJSONObject;
  CoinCode: string;
  Value: double;
  KRW: Integer;
begin
  result := false;

  KRW := Balance;
  CoinCode := mtBalance.FieldByName('coin').AsString;
  if CoinCode = 'krw' then
    Exit;

  Value := APrice * ACount;

  if Value > KRW then
  begin
    TGlobal.Obj.ApplicationMessage(msError, '�ż�����', '�ֹ��ݾ� �ʰ� - ' + FormatFloat('#,##0.00',
      KRW) + '��');
    Exit;
  end;

  res := Order(APrice, ACount, CoinCode, rtLimitSell);
  result := res.GetString('result') = 'success';

  result := res.GetString('result') = 'success';
  if result then
    LimitOrder
  else
    TGlobal.Obj.ApplicationMessage(msError, 'LimitBid', res.GetString('result'));
end;

procedure TdmDataProvider.LimitOrder;
var
  Params, JSONObject, _Order: TJSONObject;
  LimitOrders: TJSONArray;
  MyOrder: TJSONValue;
  CoinCode: string;
  DateTime: TDateTime;
begin
  CoinCode := mtBalance.FieldByName('coin').AsString;

  if CoinCode = 'krw' then
    Exit;

  Params := TJSONObject.Create;
  Params.AddPair('currency', CoinCode);
  JSONObject := smDataProviderClient.Order(Integer(rtMyLimitOrders), Params);

  LimitOrders := JSONObject.GetValue('limitOrders') as TJSONArray;

  mtMyLimitOrder.Close;
  mtMyLimitOrder.Open;

  for MyOrder in LimitOrders do
  begin
    _Order := MyOrder as TJSONObject;

    mtMyLimitOrder.Insert;
    DateTime := UnixToDateTime(_Order.GetString('timestamp').ToInteger);
    DateTime := IncHour(DateTime, 9);
    mtMyLimitOrder.FieldByName('order_stamp').AsSQLTimeStamp :=
      DateTimeToSQLTimeStamp(DateTime);
    mtMyLimitOrder.FieldByName('price').AsFloat := _Order.GetString('price').ToDouble;
    mtMyLimitOrder.FieldByName('amount').AsFloat := _Order.GetString('qty').ToDouble;
    mtMyLimitOrder.FieldByName('order_type').AsString := _Order.GetString('type');
    mtMyLimitOrder.FieldByName('order_id').AsString := _Order.GetString('orderId');
    mtMyLimitOrder.FieldByName('coin').AsString := CoinCode;
    mtMyLimitOrder.CommitUpdates;
  end;
end;

procedure TdmDataProvider.mtMyLimitOrderorder_typeGetText(Sender: TField; var Text: string;
  DisplayText: Boolean);
begin
  if Sender.AsString = 'ask' then
    Text := '�ŵ�'
  else if Sender.AsString = 'bid' then
    Text := '�ż�'
  else
    Text := '�˼�����'
end;

procedure TdmDataProvider.mtTickCalcFields(DataSet: TDataSet);
begin
  if DataSet.FieldByName('yesterday_volume').AsFloat <> 0 then
    DataSet.FieldByName('volume_rate').AsFloat :=
      (DataSet.FieldByName('volume').AsFloat - DataSet.FieldByName('yesterday_volume').AsFloat)
      / DataSet.FieldByName('yesterday_volume').AsFloat * 100;

  if DataSet.FieldByName('yesterday_last').AsFloat <> 0 then
    DataSet.FieldByName('price_rate').AsFloat :=
      (DataSet.FieldByName('last').AsFloat - DataSet.FieldByName('yesterday_last').AsFloat) /
      DataSet.FieldByName('yesterday_last').AsFloat * 100;
end;

procedure TdmDataProvider.mtTickcoinGetText(Sender: TField; var Text: string;
  DisplayText: Boolean);
begin
  Text := UpperCase(Sender.AsString);
end;

procedure TdmDataProvider.mtTickPeriodCalcFields(DataSet: TDataSet);
var
  Price, volume: double;
  Max, Min: double;
  TodayMax, TodayMin: double;
begin
  if DataSet.FieldByName('yesterday_volume').AsFloat <> 0 then
  begin
    DataSet.FieldByName('volume_rate').AsFloat :=
      (DataSet.FieldByName('volume').AsFloat - DataSet.FieldByName('yesterday_volume').AsFloat)
      / DataSet.FieldByName('yesterday_volume').AsFloat * 100;
  end;

  volume := DataSet.FieldByName('volume').AsFloat;
  Max := mtHighLow.FieldByName('high_volume').AsFloat;
  Min := mtHighLow.FieldByName('low_volume').AsFloat;
  if volume > Max then
    Min := 0;
  DataSet.FieldByName('volume_avg').AsFloat := (volume - Min) / (Max - Min) * 100;

  Price := DataSet.FieldByName('price').AsFloat;
  Max := mtHighLow.FieldByName('high_price').AsFloat;
  Min := mtHighLow.FieldByName('low_price').AsFloat;
  TodayMax := mtTick.FieldByName('high_price').AsFloat;
  TodayMin := mtTick.FieldByName('low_price').AsFloat;

  Max := MaxValue([Max, TodayMax]);
  Min := MinValue([Min, TodayMin]);
  DataSet.FieldByName('stoch').AsFloat := (Price - Min) / (Max - Min) * 100;

  if DataSet.FieldByName('yesterday_last').AsFloat <> 0 then
    DataSet.FieldByName('price_rate').AsFloat :=
      (DataSet.FieldByName('price').AsFloat - DataSet.FieldByName('yesterday_last').AsFloat) /
      DataSet.FieldByName('yesterday_last').AsFloat * 100;
end;

procedure TdmDataProvider.Tick;
var
  JSONObject, _Tick: TJSONObject;

  DateTime: TDateTime;
  I: Integer;
  BookMark: TBookmark;
begin
  JSONObject := smDataProviderClient.PublicInfo(Integer(rtTicker), 'currency=all');

  DateTime := UnixToDateTime(JSONObject.GetString('timestamp').ToInteger);
  DateTime := IncHour(DateTime, 9);
  TView.Obj.sp_AsyncMessage('TickStamp', DateTime.FormatWithoutMSec);

  BookMark := mtTick.BookMark;
  mtTick.DisableControls;
  try
    for I := Low(Coins) to High(Coins) do
    begin
      if Coins[I] = 'krw' then
        Continue;

      if mtTick.Locate('coin', Coins[I]) then
        mtTick.Edit
      else
        mtTick.Insert;

      _Tick := JSONObject.GetJSONObject(Coins[I]);
      mtTick.FieldByName('coin').AsString := Coins[I];
      mtTick.FieldByName('last').AsFloat := _Tick.GetString('last').ToDouble;
      mtTick.FieldByName('volume').AsFloat := _Tick.GetString('volume').ToDouble;
      mtTick.FieldByName('first').AsFloat := _Tick.GetString('first').ToDouble;
      mtTick.FieldByName('yesterday_volume').AsFloat :=
        _Tick.GetString('yesterday_volume').ToDouble;
      mtTick.FieldByName('yesterday_last').AsFloat :=
        _Tick.GetString('yesterday_last').ToDouble;
      mtTick.FieldByName('high_price').AsFloat := _Tick.GetString('high').ToDouble;
      mtTick.FieldByName('low_price').AsFloat := _Tick.GetString('low').ToDouble;
      mtTick.CommitUpdates;
    end;
  finally
    mtTick.EnableControls;
  end;

  if mtTick.BookmarkValid(BookMark) then
    mtTick.BookMark := BookMark;
end;

function TdmDataProvider.GetsmDataLoaderClient: TsmDataLoaderClient;
begin
  if FsmDataLoaderClient = nil then
    FsmDataLoaderClient := TsmDataLoaderClient.Create(DSRestConnection, FInstanceOwner);

  result := FsmDataLoaderClient;
end;

end.
