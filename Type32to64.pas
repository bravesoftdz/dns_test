unit Type32to64;

interface

//clq Ϊ�� ios64 λ�����ͨ��������������
//����ֱ�Ӳο� ios �� uint16_t ��������
//ͨѶЭ��Ͷ�ȡ������ļ�ʱ��Ҫ�õ�

//uses
//  System;

type
  //uint16_t opCode;//:WORD;   //��������//word Ϊһ���ֵ��������ֽڣ������� 16 λ
  //uint8_t Version;//:Byte;     //Э��汾//Ŀǰ pc ������Ϊ 0, mac Ϊ 1 ���尴�ĵ� "3.0�ṹ��Э��.doc"
  uint8   = Byte;
  uint16  = Word;//system.UInt16;//LongWord; //�Ƿ�� 32 64 ���Կ� xe10 �İ���
  uint32  = Cardinal;//:Cardinal;      //���ݳ���//Cardinal Ҳ���Կ�
  //int64   = System.UInt64;//d7 ��û�� int64 �� unit64 �Ķ���,����ֱ���� int64 �Ϳ�����
  int8    = ShortInt;//system.Int8;
  int16   = SmallInt;
  int32   = Integer; //�Ի���,�����Ȼ�ǿ�ƽ̨��

  bool8 = False..Boolean(255); //�����Ͼ��� xe10 �е� ByteBool//xe 10 �µ� rtti Ҳ֧��
  //ByteBool2 = False..Boolean(256); //������ֽھͻ���2


  //�Ƚ����Ի��Ե��� longword �����ǿ�ƽ̨��

  //64 λ arm cpu ��ԭʼ Trunc ���쳣
  function Trunc64(X: Double): Int64;

implementation

//clq test
//function Trunc64(X: Real): Int64;
//{$ELSEIF defined(CPUARM)}
//function _Trunc(Val: Extended): Int64;
//var
//  SavedRoundMode: Int32;
//type
//  TWords = Array[0..3] of Word;
//  PWords = ^TWords;
//begin
//  if (PWords(@Val)^[3] and $7FFF) >= $43E0 then
//    FRaiseExcept(feeINVALID);
//  SavedRoundMode := FSetRound(ferTOWARDZERO);
//  Result := llrint(Val);
//  FSetRound(SavedRoundMode);
//end;
//{$ELSE}
function Trunc64(X: Double): Int64;
var
  yi:Double;
begin
  //ԭ Trunc ��ĳЩ����»����
  Result := 0;

  yi := 10000*10000;

  if x < yi*10000 * 100 then //100����
    Result := Trunc(x)
  else
    Result := 111;//999999;
end;



end.
