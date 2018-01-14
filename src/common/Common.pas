unit Common;

interface

uses System.SysUtils, System.Classes;

const
  PROJECT_CODE = 'Coin24';

type
  TStochType = (stNormal, stOverBought, stOverSold);
  TPriceState = (psStable, psIncrease, psDecrease);

  TCoinInfo = record
    Currency: String; // btc, xrp, qtum...
    ShortPoint: Double; // ��Ÿ �����
    LongPoint: Double; // ��Ÿ �����
    StochHour: Integer; // Stoch �ְ�/������ ����
    MinCount: Double; // �ּ� ���� ���μ�
    ShortDeal: Double; // ��Ÿ ���ʸż��ŵ� �� - �������μ� * ShortDeal
    Oper: string; // ���� - enable, disable, test
    function ToString: string;
    function ShortState(ARate: Double): TPriceState;
    function LongState(ARate: Double): TPriceState;
  end;

  TTraderOption = record
    Coins: TArray<TCoinInfo>;
  end;

const
  OPER_ENABLE = 'enable';
  OPER_DISABLE = 'disable';
  OPER_TEST = 'test';

implementation

{ TCoinInfo }

function TCoinInfo.LongState(ARate: Double): TPriceState;
begin
  if ARate > Self.LongPoint then
    result := psIncrease
  else if ARate < -Self.LongPoint then
    result := psDecrease
  else
    result := psStable;
end;

function TCoinInfo.ShortState(ARate: Double): TPriceState;
begin
  if ARate > Self.ShortPoint then
    result := psIncrease
  else if ARate < -Self.ShortPoint then
    result := psDecrease
  else
    result := psStable;
end;

function TCoinInfo.ToString: string;
begin
  result := format
    ('Currency=%s,ShortPoint=%.2f,LongPoint=%.2f,StochHour=%d,MinCount=%.4f,ShortDeal=%.2f,Oper=%s',
    [Self.Currency, Self.ShortPoint, Self.LongPoint, Self.StochHour, Self.MinCount,
    Self.ShortDeal, Self.Oper]);
end;

end.
