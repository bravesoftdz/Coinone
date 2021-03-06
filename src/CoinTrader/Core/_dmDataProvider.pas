unit _dmDataProvider;

interface

uses
  System.SysUtils, System.Classes, ClientClassesUnit, Data.DBXDataSnap, IPPeerClient,
  Data.DBXCommon, Data.DbxHTTPLayer, Data.DB, Data.SqlExpr, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, FireDAC.Comp.Client, Coinone, System.JSON,
  REST.JSON, JdcGlobal.ClassHelper, System.DateUtils, JdcGlobal.DSCommon,
  Datasnap.DSClientRest, FireDAC.Stan.StorageBin, System.Math, JdcView, JdcGlobal, ctGlobal,
  Data.SqlTimSt, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, ctOption,
  System.StrUtils;

type
  TdmDataProvider = class(TDataModule)
    mtTicker: TFDMemTable;
    mtTickervolume: TFloatField;
    mtTickerlast: TFloatField;
    mtTickerfirst: TFloatField;
    mtTickeryesterday_volume: TFloatField;
    mtTickervolume_rate: TFloatField;
    mtTickerprice_rate: TFloatField;
    mtTickercoin: TWideStringField;
    dsTicker: TDataSource;
    mtTickeryesterday_last: TFloatField;
    mtTickerPeriod: TFDMemTable;
    WideStringField1: TWideStringField;
    FloatField1: TFloatField;
    FloatField4: TFloatField;
    FloatField6: TFloatField;
    DSRestConnection: TDSRestConnection;
    mtTickerPeriodyesterday_last: TFloatField;
    mtTickerPeriodtick_stamp: TSQLTimeStampField;
    FDStanStorageBinLink: TFDStanStorageBinLink;
    mtTickerPeriodvolume_avg: TFloatField;
    mtTickerPeriodstoch: TFloatField;
    mtTickerhigh: TFloatField;
    mtTickerlow_price: TFloatField;
    mtBalance: TFDMemTable;
    WideStringField2: TWideStringField;
    FloatField5: TFloatField;
    FloatField8: TFloatField;
    FloatField9: TFloatField;
    dsBalance: TDataSource;
    mtLimitOrders: TFDMemTable;
    FloatField10: TFloatField;
    FloatField11: TFloatField;
    mtLimitOrdersorder_stamp: TSQLTimeStampField;
    mtLimitOrdersorder_type: TWideStringField;
    dsLimitOrders: TDataSource;
    mtLimitOrdersorder_id: TWideStringField;
    mtLimitOrderscoin: TWideStringField;
    mtCompleteOrders: TFDMemTable;
    WideStringField3: TWideStringField;
    SQLTimeStampField1: TSQLTimeStampField;
    FloatField12: TFloatField;
    FloatField13: TFloatField;
    WideStringField4: TWideStringField;
    WideStringField5: TWideStringField;
    dsCompleteOrders: TDataSource;
    mtCompleteOrderslast: TFloatField;
    mtTickerPeriodhigh_price: TFloatField;
    mtTickerPeriodlow_price: TFloatField;
    mtOrder: TFDMemTable;
    mtOrderprice: TFloatField;
    mtOrderqty: TFloatField;
    mtOrderorder_stamp: TSQLTimeStampField;
    mtOrderorder_type: TWideStringField;
    mtComplete: TFDMemTable;
    SQLTimeStampField3: TSQLTimeStampField;
    FloatField2: TFloatField;
    FloatField3: TFloatField;
    WideStringField7: TWideStringField;
    mtTickerPeriodhigh_volume: TFloatField;
    mtTickerPeriodlow_volume: TFloatField;
    mtBalanceavail: TFloatField;
    mtDailyBalance: TFDMemTable;
    SQLTimeStampField4: TSQLTimeStampField;
    FloatField7: TFloatField;
    FloatField14: TFloatField;
    procedure mtTickerCalcFields(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure mtTickerPeriodCalcFields(DataSet: TDataSet);
    procedure mtLimitOrdersorder_typeGetText(Sender: TField; var Text: string;
      DisplayText: Boolean);
    procedure mtTickercoinGetText(Sender: TField; var Text: string; DisplayText: Boolean);
    procedure mtTickerprice_rateGetText(Sender: TField; var Text: string;
      DisplayText: Boolean);
  private
    FCoinone: TCoinone;

    FInstanceOwner: Boolean;
    FsmDataProviderClient: TsmDataProviderClient;
    FsmDataLoaderClient: TsmDataLoaderClient;

    FOldPrice, FUpSum, FDownSum: Integer;
    FYesterDayValue: Integer;

    function Order(APrice, ACount: double; ACoin: string; AType: TRequestType): TJSONObject;
    function GetsmDataProviderClient: TsmDataProviderClient;
    function GetsmDataLoaderClient: TsmDataLoaderClient;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Init;
    procedure Tick;
    procedure ChartData(AChartDay: Integer; AShortStoch, ALongStoch: string);

    function Balance: Integer;

    function MarketAsk(Value: Integer): Boolean;
    function MarketBid(Value: Integer): Boolean;

    function LimitAsk(APrice, ACount: double): Boolean;
    function LimitBid(APrice, ACount: double): Boolean;

    procedure LimitOrders;
    procedure CancelOrder;
    procedure CompleteOrders(ACurrency: string);
    procedure DailyCount;

    function GetClientInfo: TClientInfo;

    property InstanceOwner: Boolean read FInstanceOwner write FInstanceOwner;
    property smDataProviderClient: TsmDataProviderClient read GetsmDataProviderClient
      write FsmDataProviderClient;
    property smDataLoaderClient: TsmDataLoaderClient read GetsmDataLoaderClient
      write FsmDataLoaderClient;

    property YesterDayValue: Integer read FYesterDayValue write FYesterDayValue;
  end;

var
  dmDataProvider: TdmDataProvider;

implementation

{ %CLASSGROUP 'Vcl.Controls.TControl' }

{$R *.dfm}

function TdmDataProvider.MarketAsk(Value: Integer): Boolean;
var
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
    TGlobal.Obj.ApplicationMessage(msError, '매도실패', '주문금액 초과 - ' + FormatFloat('#,##0',
      mtBalance.FieldByName('krw').AsFloat) + '원');
    Exit;
  end;

  Price := mtBalance.FieldByName('last').AsFloat;
  Count := Value / Price;

  try
    Order(Price, Count, CoinCode, rtLimitSell);
    LimitOrders;
    result := true;
  except
    on E: Exception do
      TGlobal.Obj.ApplicationMessage(msError, 'MarketAsk', E.Message);
  end;
end;

function TdmDataProvider.Balance: Integer;

  function GetYesterdayBalance: Integer;
  var
    JSONObject, _Balance: TJSONObject;
    DailyBalance: TJSONArray;
  begin
    JSONObject := FCoinone.AccountInfo(rtDailyBalance);
    TGlobal.Obj.ApplicationMessage(msDebug, 'DailyBalance', JSONObject.ToString);
    try
      DailyBalance := JSONObject.GetJSONArray('dailyBalance');
      _Balance := DailyBalance.Items[0] as TJSONObject;

      if Assigned(_Balance) then
        result := _Balance.GetString('value').ToInteger
      else
        result := 0;
    finally
      JSONObject.Free;
    end;
  end;

var
  JSONObject, _Balance: TJSONObject;

  I: Integer;
  BookMark: TBookmark;
  Amount, Price, Avail: double;
  KRW, Total: double;
begin
  result := 0;
  Total := 0;

  FYesterDayValue := GetYesterdayBalance;
  Tick;
  JSONObject := FCoinone.AccountInfo(rtBalance);
  try
    BookMark := mtBalance.BookMark;
    mtBalance.DisableControls;
    try
      for I := Low(Coins) to High(Coins) do
      begin
        if MatchText(Coins[I], ['bch', 'btg']) then
          Continue;

        if mtTicker.Locate('coin', Coins[I]) then
        begin
          Price := mtTicker.FieldByName('last').AsFloat;
        end
        else
          Price := 1;

        if mtBalance.Locate('coin', Coins[I]) then
          mtBalance.Edit
        else
          mtBalance.Insert;

        _Balance := JSONObject.GetJSONObject(Coins[I]);

        Amount := _Balance.GetString('balance').ToDouble;
        Avail := _Balance.GetString('avail').ToDouble;
        KRW := Price * Amount;
        Total := Total + KRW;

        // KRW 가용 잔액
        if Coins[I] = 'krw' then
          result := _Balance.GetString('avail').ToInteger;

        mtBalance.FieldByName('coin').AsString := Coins[I];
        mtBalance.FieldByName('amount').AsFloat := Amount;
        mtBalance.FieldByName('avail').AsFloat := Avail;
        mtBalance.FieldByName('last').AsFloat := Price;
        mtBalance.FieldByName('krw').AsFloat := KRW;
        mtBalance.CommitUpdates;
      end;

      mtBalance.First;
    finally
      mtBalance.EnableControls;
    end;

    if mtBalance.BookmarkValid(BookMark) then
      mtBalance.BookMark := BookMark;

  finally
    JSONObject.Free;
  end;

  TView.Obj.sp_AsyncMessage('KrwValue', Total.ToString);
end;

function TdmDataProvider.MarketBid(Value: Integer): Boolean;
var
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
    TGlobal.Obj.ApplicationMessage(msError, '매수실패', '주문금액 초과 - ' + FormatFloat('#,##0',
      KRW) + '원');
    Exit;
  end;

  Price := mtBalance.FieldByName('last').AsFloat;
  Count := Value / Price;
  try
    Order(Price, Count, CoinCode, rtLimitBuy);
    LimitOrders;
    result := true;
  except
    on E: Exception do
      TGlobal.Obj.ApplicationMessage(msError, 'MarketBid', E.Message);
  end;

end;

procedure TdmDataProvider.CancelOrder;
var
  Params: TJSONObject;
begin

  if mtLimitOrders.IsEmpty then
    Exit;

  Params := TJSONObject.Create;
  Params.AddPair('order_id', mtLimitOrders.FieldByName('order_id').AsString);
  Params.AddPair('price', mtLimitOrders.FieldByName('price').AsString);
  Params.AddPair('qty', mtLimitOrders.FieldByName('amount').AsString);

  if mtLimitOrders.FieldByName('order_type').AsString = 'ask' then
    Params.AddPair('is_ask', '1')
  else
    Params.AddPair('is_ask', '0');

  Params.AddPair('currency', mtLimitOrders.FieldByName('coin').AsString);

  try
    FCoinone.Order(rtCancelOrder, Params);
    LimitOrders;
  except
    on E: Exception do
      TGlobal.Obj.ApplicationMessage(msError, 'CancelOrder', E.Message);
  end;

end;

procedure TdmDataProvider.ChartData(AChartDay: Integer; AShortStoch, ALongStoch: string);

  function CreateTickerParams(ACoin: string): TJSONObject;
  begin
    result := TJSONObject.Create;
    result.AddPair('coin_code', UpperCase(ACoin));
    result.AddPair('begin_time', IncDay(Now, -AChartDay).ToISO8601);
    result.AddPair('end_time', Now.ToISO8601);

    result.AddPair('short_period', AShortStoch);
    result.AddPair('long_period', ALongStoch);
  end;

  procedure Complete(ACurrency: string);
  var
    Params, JSONObject, _Order: TJSONObject;
    Orders: TJSONArray;
    MyOrder: TJSONValue;
    DateTime: TDateTime;
  begin
    if ACurrency = 'krw' then
      Exit;

    Params := TJSONObject.Create;
    Params.AddPair('currency', ACurrency);
    JSONObject := FCoinone.Order(rtMyCompleteOrders, Params);

    Orders := JSONObject.GetValue('completeOrders') as TJSONArray;

    mtComplete.Close;
    mtComplete.Open;

    for MyOrder in Orders do
    begin
      _Order := MyOrder as TJSONObject;
      DateTime := UnixToDateTime(_Order.GetString('timestamp').ToInteger);
      DateTime := IncHour(DateTime, 9);

      if DateTime < IncDay(Now, -AChartDay) then
        Continue;

      mtComplete.Append;
      mtComplete.FieldByName('order_stamp').AsSQLTimeStamp := DateTimeToSQLTimeStamp(DateTime);
      mtComplete.FieldByName('price').AsFloat := _Order.GetString('price').ToDouble;
      mtComplete.FieldByName('amount').AsFloat := _Order.GetString('qty').ToDouble;
      mtComplete.FieldByName('order_type').AsString := _Order.GetString('type');
      mtComplete.CommitUpdates;
    end;
  end;

var
  Params: TJSONObject;
  Coin: String;
begin
  FUpSum := 0;
  FDownSum := 0;
  FOldPrice := 0;

  Coin := mtTicker.FieldByName('coin').AsString;
  Params := CreateTickerParams(Coin);
  mtTickerPeriod.LoadFromDSStream(smDataProviderClient.Ticker(Params));

  Params := TJSONObject.Create;
  Params.AddPair('coin_code', UpperCase(Coin));
  Params.AddPair('begin_time', IncDay(Now, -AChartDay).ToISO8601);
  Params.AddPair('end_time', Now.ToISO8601);
  Params.AddPair('user_id', TGlobal.Obj.UserID);
  mtOrder.LoadFromDSStream(smDataProviderClient.Orders(Params));
  Complete(Coin);
end;

constructor TdmDataProvider.Create(AOwner: TComponent);
begin
  inherited;
  FInstanceOwner := true;

  DSRestConnection.Host := TOption.Obj.ConnInfo.StringValue;
  DSRestConnection.Port := TOption.Obj.ConnInfo.IntegerValue;
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
  result := FCoinone.Order(AType, Params);
end;

procedure TdmDataProvider.CompleteOrders(ACurrency: string);
var
  Params, JSONObject, _Order: TJSONObject;
  Orders: TJSONArray;
  MyOrder: TJSONValue;
  DateTime: TDateTime;
begin
  if ACurrency = 'krw' then
    Exit;

  Params := TJSONObject.Create;
  Params.AddPair('currency', ACurrency);
  JSONObject := FCoinone.Order(rtMyCompleteOrders, Params);

  Orders := JSONObject.GetValue('completeOrders') as TJSONArray;

  mtCompleteOrders.Close;
  mtCompleteOrders.Open;

  mtCompleteOrders.DisableControls;
  try

    for MyOrder in Orders do
    begin
      _Order := MyOrder as TJSONObject;
      DateTime := UnixToDateTime(_Order.GetString('timestamp').ToInteger);
      DateTime := IncHour(DateTime, 9);

      mtCompleteOrders.Append;
      mtCompleteOrders.FieldByName('order_stamp').AsSQLTimeStamp :=
        DateTimeToSQLTimeStamp(DateTime);
      mtCompleteOrders.FieldByName('price').AsFloat := _Order.GetString('price').ToDouble;
      mtCompleteOrders.FieldByName('amount').AsFloat := _Order.GetString('qty').ToDouble;
      mtCompleteOrders.FieldByName('order_type').AsString := _Order.GetString('type');
      mtCompleteOrders.FieldByName('order_id').AsString := _Order.GetString('orderId');
      mtCompleteOrders.FieldByName('fee').AsString := _Order.GetString('fee');
      mtCompleteOrders.FieldByName('coin').AsString := ACurrency;
      mtCompleteOrders.CommitUpdates;
    end;
    mtCompleteOrders.First;
  finally
    mtCompleteOrders.EnableControls;
  end;
end;

procedure TdmDataProvider.DailyCount;
var
  CoinCode: string;
  JSONObject, _Balance: TJSONObject;
  DailyBalance: TJSONArray;
  I: Integer;
  DateTime: TDateTime;
begin
  CoinCode := mtBalance.FieldByName('coin').AsString;

  mtDailyBalance.Close;
  mtDailyBalance.Open;

  JSONObject := FCoinone.AccountInfo(rtDailyBalance);
  try
    DailyBalance := JSONObject.GetJSONArray('dailyBalance');

    for I := 0 to DailyBalance.Count - 1 do
    begin
      _Balance := DailyBalance.Items[I] as TJSONObject;

      DateTime := UnixToDateTime(_Balance.GetString('timestamp').ToInteger);

      if DateTime < IncMonth(Now, -1) then
        Break;

      mtDailyBalance.Append;
      mtDailyBalance.FieldByName('time_stamp').AsSQLTimeStamp :=
        DateTimeToSQLTimeStamp(DateTime);
      mtDailyBalance.FieldByName('coin_count').AsFloat := _Balance.GetString(CoinCode)
        .ToDouble;
      mtDailyBalance.FieldByName('total_value').AsFloat := _Balance.GetString('value')
        .ToInteger;
    end;
    mtDailyBalance.CommitUpdates;
  finally
    JSONObject.Free;
  end;
end;

procedure TdmDataProvider.DataModuleCreate(Sender: TObject);
begin
  mtTicker.Open;
  mtBalance.Open;
end;

destructor TdmDataProvider.Destroy;
begin
  FCoinone.Free;

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

procedure TdmDataProvider.Init;
begin
  FCoinone := TCoinone.Create(TOption.Obj.AccessToken, TOption.Obj.SecretKey);
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
    TGlobal.Obj.ApplicationMessage(msError, '매도실패', '주문수량 초과 - ' + FormatFloat('#,##0.00',
      mtBalance.FieldByName('amount').AsFloat));
    Exit;
  end;

  res := Order(APrice, ACount, CoinCode, rtLimitSell);
  result := res.GetString('result') = 'success';

  if result then
    LimitOrders
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
    TGlobal.Obj.ApplicationMessage(msError, '매수실패', '주문금액 초과 - ' + FormatFloat('#,##0.00',
      KRW) + '원');
    Exit;
  end;

  res := Order(APrice, ACount, CoinCode, rtLimitBuy);
  result := res.GetString('result') = 'success';

  if result then
    LimitOrders
  else
    TGlobal.Obj.ApplicationMessage(msError, 'LimitBid', res.GetString('result'));
end;

procedure TdmDataProvider.LimitOrders;
var
  Params, JSONObject, _Order: TJSONObject;
  _LimitOrders: TJSONArray;
  MyOrder: TJSONValue;
  CoinCode: string;
  DateTime: TDateTime;
begin
  CoinCode := mtBalance.FieldByName('coin').AsString;

  if CoinCode = 'krw' then
    Exit;

  Params := TJSONObject.Create;
  Params.AddPair('currency', CoinCode);
  JSONObject := FCoinone.Order(rtMyLimitOrders, Params);
  _LimitOrders := JSONObject.GetValue('limitOrders') as TJSONArray;
  mtLimitOrders.Close;
  mtLimitOrders.Open;

  for MyOrder in _LimitOrders do
  begin
    _Order := MyOrder as TJSONObject;

    mtLimitOrders.Insert;
    DateTime := UnixToDateTime(_Order.GetString('timestamp').ToInteger);
    DateTime := IncHour(DateTime, 9);
    mtLimitOrders.FieldByName('order_stamp').AsSQLTimeStamp :=
      DateTimeToSQLTimeStamp(DateTime);
    mtLimitOrders.FieldByName('price').AsFloat := _Order.GetString('price').ToDouble;
    mtLimitOrders.FieldByName('amount').AsFloat := _Order.GetString('qty').ToDouble;
    mtLimitOrders.FieldByName('order_type').AsString := _Order.GetString('type');
    mtLimitOrders.FieldByName('order_id').AsString := _Order.GetString('orderId');
    mtLimitOrders.FieldByName('coin').AsString := CoinCode;
    mtLimitOrders.CommitUpdates;
  end;
end;

procedure TdmDataProvider.mtLimitOrdersorder_typeGetText(Sender: TField; var Text: string;
  DisplayText: Boolean);
begin
  if Sender.AsString = 'ask' then
    Text := '매도'
  else if Sender.AsString = 'bid' then
    Text := '매수'
  else
    Text := ''
end;

procedure TdmDataProvider.mtTickerCalcFields(DataSet: TDataSet);
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

procedure TdmDataProvider.mtTickercoinGetText(Sender: TField; var Text: string;
  DisplayText: Boolean);
begin
  Text := UpperCase(Sender.AsString);
end;

procedure TdmDataProvider.mtTickerPeriodCalcFields(DataSet: TDataSet);

  function CalcStoch(APrice: double; HighName, LowName: string): double;
  var
    Max, Min: double;
  begin
    Max := DataSet.FieldByName(HighName).AsFloat;
    Min := DataSet.FieldByName(LowName).AsFloat;
    if Max = Min then
      result := 0
    else
      result := (APrice - Min) / (Max - Min) * 100;
  end;

var
  Price: double;
begin
  Price := DataSet.FieldByName('price').AsFloat;
  DataSet.FieldByName('short_stoch').AsFloat := CalcStoch(Price, 'short_high_price',
    'short_low_price');
  DataSet.FieldByName('long_stoch').AsFloat := CalcStoch(Price, 'long_high_price',
    'long_low_price');
end;

procedure TdmDataProvider.mtTickerprice_rateGetText(Sender: TField; var Text: string;
  DisplayText: Boolean);
begin
  if Sender.AsFloat < 0 then
    Text := Format('%.2f', [Sender.AsFloat])
  else
    Text := Format('+%.2f', [Sender.AsFloat]);
end;

procedure TdmDataProvider.Tick;
var
  JSONObject, _Ticker: TJSONObject;

  DateTime: TDateTime;
  I: Integer;
  BookMark: TBookmark;
begin
  JSONObject := FCoinone.PublicInfo(rtTicker, 'currency=all');
  try
    DateTime := UnixToDateTime(JSONObject.GetString('timestamp').ToInteger);
    DateTime := IncHour(DateTime, 9);
    TView.Obj.sp_AsyncMessage('TickStamp', DateTime.FormatWithoutMSec);

    BookMark := mtTicker.BookMark;
    mtTicker.DisableControls;
    try
      for I := Low(Coins) to High(Coins) do
      begin
        if MatchText(Coins[I], ['krw', 'bch', 'btg']) then
          Continue;

        if mtTicker.Locate('coin', Coins[I]) then
          mtTicker.Edit
        else
          mtTicker.Insert;

        _Ticker := JSONObject.GetJSONObject(Coins[I]);
        mtTicker.FieldByName('coin').AsString := Coins[I];
        mtTicker.FieldByName('last').AsFloat := _Ticker.GetString('last').ToDouble;
        mtTicker.FieldByName('volume').AsFloat := _Ticker.GetString('volume').ToDouble;
        mtTicker.FieldByName('first').AsFloat := _Ticker.GetString('first').ToDouble;
        mtTicker.FieldByName('yesterday_volume').AsFloat :=
          _Ticker.GetString('yesterday_volume').ToDouble;
        mtTicker.FieldByName('yesterday_last').AsFloat :=
          _Ticker.GetString('yesterday_last').ToDouble;
        mtTicker.FieldByName('high_price').AsFloat := _Ticker.GetString('high').ToDouble;
        mtTicker.FieldByName('low_price').AsFloat := _Ticker.GetString('low').ToDouble;
        mtTicker.CommitUpdates;
      end;
    finally
      mtTicker.EnableControls;
    end;

    if mtTicker.BookmarkValid(BookMark) then
      mtTicker.BookMark := BookMark;
  finally
    JSONObject.Free;
  end;
end;

function TdmDataProvider.GetClientInfo: TClientInfo;
begin
  try
    result := TJson.JsonToRecord<TClientInfo>(smDataProviderClient.GetClientInfo);
  except
    on E: Exception do
      TGlobal.Obj.ApplicationMessage(msError, 'GetClientInfo', E.Message);
  end;

end;

function TdmDataProvider.GetsmDataLoaderClient: TsmDataLoaderClient;
begin
  if FsmDataLoaderClient = nil then
    FsmDataLoaderClient := TsmDataLoaderClient.Create(DSRestConnection, FInstanceOwner);

  result := FsmDataLoaderClient;
end;

end.
