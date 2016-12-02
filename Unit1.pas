unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, WinSock,
  Sockets, IdTCPConnection, IdTCPClient;

type
  TForm1 = class(TForm)
    Button1: TButton;
    UdpSocket1: TUdpSocket;
    IdUDPClient1: TIdUDPClient;
    IdTCPClient1: TIdTCPClient;
    Edit1: TEdit;
    Memo1: TMemo;
    Button2: TButton;
    txtDns: TComboBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Type32to64;

{$R *.dfm}

type
  //dns ���������Ӧ����ͬһ��ʽ
  TDnsReq = packed record


  end;

  //Tag:uint16; //�����һ������Ľṹ�����ת������
  VDnsHead_tag = packed record
    QR :uint8; //(1����)����ѯ/��Ӧ�ı�־λ��1Ϊ��Ӧ��0Ϊ��ѯ��
    opcode :uint32; //(4����)�������ѯ����Ӧ������(��Ϊ0���ʾ�Ǳ�׼�ģ���Ϊ1���Ƿ���ģ���Ϊ2���Ƿ�����״̬����)��
    AA :uint8; //(1����)����Ȩ�ش�ı�־λ����λ����Ӧ��������Ч��1��ʾ���ַ�������Ȩ�޷�����(����Ȩ�޷������Ժ�������)
    TC :uint8; //(1����)���ضϱ�־λ��1��ʾ��Ӧ�ѳ���512�ֽڲ��ѱ��ض�(��ϡ����ǵ������������ضϺ�UDP�йأ��ȼ���)
    RD :uint8; //(1����)����λΪ1��ʾ�ͻ���ϣ���õ��ݹ�ش�(�ݹ��Ժ�������) //�����л���ֻ��Ҫ�����,���඼Ϊ 0
    RA :uint8; //(1����)��ֻ������Ӧ��������Ϊ1����ʾ���Եõ��ݹ���Ӧ��
    zero :array[0..2] of uint8; //(3����)����˵Ҳ֪������0�ˣ������ֶΡ�
    rcode :uint32; //(4����)�������룬��ʾ��Ӧ�Ĳ��״̬��ͨ��Ϊ0��3

  end;


  //dns ��ͷ���̶�Ϊ 12 �ֽ�(12x8=96λ)
  TDnsHead = packed record
    ID:uint16;  //����ĶԻ� id ����,����ȷ����Ӧ�Ƿ����Լ�����õ���
    //Tag:uint16; //�����һ������Ľṹ�����ת������
    Flags:uint16; //�����һ������Ľṹ�����ת������ //����һ���� 0x100

    QDCOUNT:uint16; //ռ16λ��2�ֽڡ���ѯ��¼�ĸ��� //������    //������һ��Ϊ 1
    ANCOUNT:uint16; //ռ16λ��2�ֽڡ��ظ���¼�ĸ��� //�ش�RR��  //������һ��Ϊ 0
    NSCOUNT:uint16; //ռ16λ��2�ֽڡ�Ȩ����¼�ĸ��� //Ȩ��RR��  //������һ��Ϊ 0
    ARCOUNT:uint16; //ռ16λ��2�ֽڡ������¼�ĸ��� //����RR��  //������һ��Ϊ 0

  end;

  //������//���е���Դ����
  TDnsQuery = packed record
    QNAME:string; //Ҫ��ѯ������,����ʽ����,�����е� . Ҫ������� //bbs.zzsy.com=>3bbs4zzsy3com0����.�ֿ�bbs��zzsy��com�������֡�ÿ�����ֵĳ���Ϊ3��4��3
    QTYPE:uint16;  //��ѯ����,һ����ָ A ��¼���� MX ��¼//
    //***//A=0x01, //ָ������� IP ��ַ��
    //NS=0x02, //ָ��������������� DNS ���Ʒ�������
    //MD=0x03, //ָ���ʼ�����վ���������Ѿ���ʱ�ˣ�ʹ��MX���棩
    //MF=0x04, //ָ���ʼ���תվ���������Ѿ���ʱ�ˣ�ʹ��MX���棩
    //CNAME=0x05, //ָ�����ڱ����Ĺ淶���ơ�
    //SOA=0x06, //ָ������ DNS ����ġ���ʼ��Ȩ��������
    //MB=0x07, //ָ������������
    //MG=0x08, //ָ���ʼ����Ա��
    //MR=0x09, //ָ���ʼ�������������
    //NULL=0x0A, //ָ���յ���Դ��¼
    //WKS=0x0B, //������֪����
    //PTR=0x0C, //�����ѯ�� IP ��ַ����ָ���������������ָ��ָ��������Ϣ��ָ�롣
    //HINFO=0x0D, //ָ������� CPU �Լ�����ϵͳ���͡�
    //MINFO=0x0E, //ָ��������ʼ��б���Ϣ��
    //***//MX=0x0F, //ָ���ʼ���������
    //TXT=0x10, //ָ���ı���Ϣ��
    //AAAA=0x1c,//IPV6��Դ��¼��
    //UINFO=0x64, //ָ���û���Ϣ��
    //UID=0x65, //ָ���û���ʶ����
    //GID=0x66, //ָ�����������ʶ����
    //ANY=0xFF //ָ�������������͡�

    QCLASS:uint16; //�������������,һ�㶼�� internet
    //***///IN=0x01, //ָ�� Internet ���
    //CSNET=0x02, //ָ�� CSNET ��𡣣��ѹ�ʱ��
    //CHAOS=0x03, //ָ�� Chaos ���
    //HESIOD=0x04,//ָ�� MIT Athena Hesiod ���
    //ANY=0xFF //ָ���κ���ǰ�г���ͨ�����


  end;


  TDnsRequest = packed record
    Head:TDnsHead;
    Query:TDnsQuery; //������ʵӦ���� Queries ������,����һ��Ͳ�һ��,���Լ�д����
  end;

  (*
    ����(2�ֽڻ򲻶���)

    ��¼����Դ���ݶ�Ӧ�����֣����ĸ�ʽ�Ͳ�ѯ���ֶθ�ʽ��ͬ���������������ظ�����ʱ������Ҫʹ��2�ֽڵ�ƫ��ָ�����滻�����磬����Դ��¼�У�����ͨ���ǲ�ѯ���ⲿ�ֵ��������ظ�������Ҫ��ָ��ָ���ѯ���ⲿ�ֵ�����������ָ����ô�ã�TCP/IP��������У���2�ֽڵ�ָ�룬��ǰ���������λ��11������ʶ��ָ�롣����14λ�ӱ��Ŀ�ʼ������(��0��ʼ)��ָ���ñ����е���Ӧ�ֽ�����ע�⣬DNS���ĵĵ�һ���ֽ����ֽ�0���ڶ����������ֽ�1��һ����Ӧ�����У���Դ���ֵ���������ָ��C00C(1100000000001100��12�������ײ�����ĳ���)���պ�ָ�����󲿷ֵ�����[1]��
  *)


  //��Ӧ����//���е���Դ����
  TDnsAnswer = packed record
    RNAME:string; //:�ظ���ѯ����������������
    //RNAME_P:uint16;//c0 0c Ϊ����ָ��//ʵ�����ﶼΪָ��,��дʵ�ʵ������ַ���//�ƺ���2�ֽ�//c0 �ƺ��ǹ̶���ָ��ֵ, 0c ��ʾ 12,�պ���ͷ�������������,������ʾ�ظ�����������,���ֵ�����ǹ̶���,����Ҫ�������
    RTYPE:uint16; //:�ظ������͡�2�ֽڣ����ѯͬ�塣ָʾRDATA�е���Դ��¼���͡�
    RCLASS:uint16; //:�ظ����ࡣ2�ֽڣ����ѯͬ�塣ָʾRDATA�е���Դ��¼�ࡣ
    RTTL:uint32; //:����ʱ�䡣4�ֽڣ�ָʾRDATA�е���Դ��¼�ڻ��������ʱ�䡣
    RDLENGTH:uint16; //:���ȡ�2�ֽڣ�ָʾRDATA��ĳ��ȡ�
    RDATA:string; //:��Դ��¼�������壬��TYPE�Ĳ�ͬ���˼�¼�ĸ�ʾ��ͬ��ͨ��һ��MX��¼����һ��2�ֽڵ�ָʾ���ʼ������������ȼ�ֵ�����������ʼ�����������ɵġ�


  end;



  //��Ӧ����
  TDnsResponse = packed record
    Head:TDnsHead;
    Queries:array of TDnsQuery;  //��Ӧ�е�����,ֻҪ��һ��Ҳ�ǿ��Ե�//��Ӧ��Ҳ������
    Answers:array of TDnsAnswer; //��Ӧ�е�����,ֻҪ��һ��Ҳ�ǿ��Ե�
    IP:array of string; //�� TDnsAnswer �м�������� ip
  end;


//����תΪ���ĸ�ʽ
//bbs.zzsy.com=>3bbs4zzsy3com0����.�ֿ�bbs��zzsy��com�������֡�ÿ�����ֵĳ���Ϊ3��4��3
function GetHostPack(host:string):string;
var
  i:Integer;
  c:AnsiChar;
  count:Integer;
begin
  //��Ϊ������ǰ,������ѭ���ȽϺ�

  Result := host;

  count := 0;
  for i := Length(host) downto 1 do
  begin
    c := host[i];

    if c = '.' then
    begin
      Result[i] := AnsiChar(count);
      count := 0;
      Continue;
    end;
    
    count := count + 1;
  end;

  Result := AnsiChar(count) + Result; //�������һ��

  Result := Result +#0; //����Ҫ�ӽ�������


end;

procedure TForm1.Button1Click(Sender: TObject);
var
  req:string;
  res:string;
  b1:TBits;
  host:string;
  treq:TDnsRequest;
  reqTag:VDnsHead_tag;
  mem:TMemoryStream;
  tres:TDnsResponse; //��Ӧ����
  i,k:Integer;
  ip:string;

  //��Ӧ���ж���һ������,�պ����� #0 ��β��,���Կ��Լ�
  function ReadName:string;
  var
    j:Integer;
    c:AnsiChar;
    oldPos:Integer; //��Ϊ�����ֽڱ�ʾָ��Ĳ���,����Ҫ��¼��ǰ��λ��
    offset:uint16;
    tmp:string;
    _count:Integer;
  begin


    Result := '';
    _count := 0;

    while mem.Position < mem.Size do
    begin

      //--------------------------------------------------
      //Ҫ�ȿ����ǲ���ָ��,ָ��Ļ��������ֽڱ�ʾλ��,ͬʱ�ڵ�һ���ֽڵ�ǰ��λΪ11 ��  11000000 (0xC0)(192)
      oldPos := mem.Position;
      mem.Read(c, 1);
      if Byte(c)>=192 then
      begin
        mem.Position := oldPos; //�����ȡֻ����̽�Ե�,����Ҫ�ָ�λ��
        mem.Read(offset, 2);
        //offset := offset and
        offset := ntohs(offset);
        offset := offset - $C000; //0xC000 = 49152

        //OFFSET�ֶ�ָ���������Ϣ��ʼ�����������ײ���ID�ֶεĵ�һ���ֽڣ���ƫ������0 ƫ����ָ���� ID �ֶεĵ�һ���ֽڣ��ȵȡ�
        //��ԭʼ�������� res ����ʼλ��

        tmp := Copy(res, offset+1, Length(res));
        tmp := PAnsiChar(tmp); //����ȫ��Ҫ,#0 ���Ҫȥ�� //��ʵ�����������Ҳ���ܻ���ָ��,����Ҫ�������ֵĻ���Ҫ�õݹ���,��������
        Result := Result + tmp;

        //mem.Position := mem.Position + Length(tmp);

        Break; //ָ��ĸ�ʽ������ʱֻ�������ĩ��,���Ե�����,��Ϊ��ʱ�ͽ�����,�ٶ�ȡһ�� 0 �ǲ��Ե�

        //Exit;
      end
      //--------------------------------------------------
      //��������һ���ֽڵĳ��ȼ��ַ���
      else
      begin
        if c = #0 then Break;

        SetLength(tmp, Byte(c));
        mem.Read(tmp[1], Byte(c));

        if Result<>'' then Result := Result + '.';

        Result := Result + tmp;
      end;

      if mem.Position>=mem.Size  //���ȱ���
      then Break;

      Inc(_count);
      if _count>1000 //��������
      then Break;

    end;//while


    Exit;

    //--------------------------------------------------
    for j := mem.Position to mem.Size-1 do
    begin
      mem.Read(c, 1);

      Result := Result + c;

      if c = #0 then Break;
    end;

    //mem.Position := oldPos;
  end;


  //��Ӧ���ж���һ������,�ɵݹ��,��ȡ��Ҫ�ص���ǰλ��//raw ��ԭʼ�ַ��� //level �ǵݹ�Ĳ��,��ֹ��ѭ��
  function ReadName2(const raw:string; const level:Integer):string;
  var
    j:Integer;
    c:AnsiChar;
    oldPos:Integer; //��Ϊ�����ֽڱ�ʾָ��Ĳ���,����Ҫ��¼��ǰ��λ��
    offset:uint16;
    tmp:string;
    _count:Integer;
    fmem:TMemoryStream;
  begin
    Result := '';

    //if level > 1 then Exit; //�ݹ��α���
    if level > 9 then Exit; //�ݹ��α���

    fmem := TMemoryStream.Create;
    //fmem.WriteBuffer(res[1], Length(res));
    fmem.WriteBuffer(raw[1], Length(raw));
    fmem.Seek(0, soFromBeginning);

    //--------------------------------------------------

    Result := '';
    _count := 0;

    while fmem.Position < fmem.Size do
    begin

      //--------------------------------------------------
      //Ҫ�ȿ����ǲ���ָ��,ָ��Ļ��������ֽڱ�ʾλ��,ͬʱ�ڵ�һ���ֽڵ�ǰ��λΪ11 ��  11000000 (0xC0)(192)
      oldPos := fmem.Position;
      fmem.Read(c, 1);
      if Byte(c)>=192 then
      begin
        fmem.Position := oldPos; //�����ȡֻ����̽�Ե�,����Ҫ�ָ�λ��
        fmem.Read(offset, 2);

        offset := ntohs(offset);
        offset := offset - $C000; //0xC000 = 49152

        //OFFSET�ֶ�ָ���������Ϣ��ʼ�����������ײ���ID�ֶεĵ�һ���ֽڣ���ƫ������0 ƫ����ָ���� ID �ֶεĵ�һ���ֽڣ��ȵȡ�
        //��ԭʼ�������� res ����ʼλ��

        tmp := Copy(res, offset+1, Length(res));
        ////tmp := PAnsiChar(tmp); //����ȫ��Ҫ,#0 ���Ҫȥ�� //��ʵ�����������Ҳ���ܻ���ָ��,����Ҫ�������ֵĻ���Ҫ�õݹ���,��������

        tmp := ReadName2(tmp, level + 1);//�������㷨Ӧ�õݹ�

        if Result<>'' then Result := Result + '.';
        
        Result := Result + tmp;

        //fmem.Position := fmem.Position + Length(tmp);

        Break; //ָ��ĸ�ʽ������ʱֻ�������ĩ��,���Ե�����,��Ϊ��ʱ�ͽ�����,�ٶ�ȡһ�� 0 �ǲ��Ե�

        //Exit;
      end
      //--------------------------------------------------
      //��������һ���ֽڵĳ��ȼ��ַ���
      else
      begin
        if c = #0 then Break;

        SetLength(tmp, Byte(c));
        fmem.Read(tmp[1], Byte(c));

        if Result<>'' then Result := Result + '.';

        Result := Result + tmp;
      end;

      if fmem.Position>=fmem.Size  //���ȱ���
      then Break;

      Inc(_count);
      if _count>1000 //��������
      then Break;

    end;//while


    fmem.Free;

  end;

  //��Ӧ���ж���ԭʼ�ַ���
  function ReadName_raw:string;
  var
    j:Integer;
    c:AnsiChar;
    oldPos:Integer; //��Ϊ�����ֽڱ�ʾָ��Ĳ���,����Ҫ��¼��ǰ��λ��
    offset:uint16;
    tmp:string;
    _count:Integer;
  begin


    Result := '';
    _count := 0;

    while mem.Position < mem.Size do
    begin

      //--------------------------------------------------
      //Ҫ�ȿ����ǲ���ָ��,ָ��Ļ��������ֽڱ�ʾλ��,ͬʱ�ڵ�һ���ֽڵ�ǰ��λΪ11 ��  11000000 (0xC0)(192)
      oldPos := mem.Position;
      mem.Read(c, 1);
      if Byte(c)>=192 then
      begin
        mem.Position := oldPos; //�����ȡֻ����̽�Ե�,����Ҫ�ָ�λ��
        //mem.Read(offset, 2);
        SetLength(tmp, 2);
        mem.Read(tmp[1], 2);


        Result := Result + tmp;

        //mem.Position := mem.Position + Length(tmp);

        Break; //ָ��ĸ�ʽ������ʱֻ�������ĩ��,���Ե�����,��Ϊ��ʱ�ͽ�����,�ٶ�ȡһ�� 0 �ǲ��Ե�

        //Exit;
      end
      //--------------------------------------------------
      //��������һ���ֽڵĳ��ȼ��ַ���
      else
      begin
        Result := Result + c;
        if c = #0 then Break;

        SetLength(tmp, Byte(c));
        mem.Read(tmp[1], Byte(c));

        //if Result<>'' then Result := Result + '.';

        Result := Result + tmp;
      end;

      if mem.Position>=mem.Size  //���ȱ���
      then Break;

      Inc(_count);
      if _count>1000 //��������
      then Break;

    end;//while

  end;


begin

  req := '';
  res := '';

  host := 'www.baidu.com';
  //host := 'lib.csdn.net';
  host := Edit1.Text;

  host := GetHostPack(host);

  treq.Query.QNAME := host;
  treq.Query.QTYPE := htons(1);//$f; // A=0x01, MX=0x0F,
  ////treq.QTYPE := htons($f);//$f; // A=0x01, MX=0x0F,
  treq.Query.QCLASS := htons(1); // internet

  FillChar(treq.Head, SizeOf(treq.Head), 0);
  Randomize();
  treq.Head.ID := Trunc((Now - Trunc(Now)) * 100000) + Random(10000);
  treq.Head.QDCOUNT := htons(1);//1;  //һ������

  //treq.Head.Tag;

  //--------------------------------------------------
  FillChar(reqTag, SizeOf(reqTag), 0);
  reqTag.QR := 0; //1Ϊ��Ӧ��0Ϊ��ѯ��
  reqTag.RD := 1; //ϣ���õ��ݹ�ش�//ֻ�����ſ���Ϊ 1,����ʵ���� Flags ��������˵�����ǹ̶���,����Ҫλ������

  ////
  treq.Head.Flags := htons($100);//0;
  //treq.Head.Flags := 0; //����ûӰ�� //ʵ���� Flags ��������˵�����ǹ̶���,����Ҫλ������//������
  //--------------------------------------------------

  mem := TMemoryStream.Create;

  //mem.WriteBuffer('aaa'[1], 3);
  mem.WriteBuffer(treq.Head, SizeOf(treq.Head));
  //ShowMessage(IntToStr(Length(treq.QNAME)));
  mem.WriteBuffer(treq.Query.QNAME[1], Length(treq.Query.QNAME));
  mem.WriteBuffer(treq.Query.QTYPE, SizeOf(treq.Query.QTYPE));
  mem.WriteBuffer(treq.Query.QCLASS, SizeOf(treq.Query.QCLASS));

  SetLength(req, mem.size);
  mem.Seek(0, soFromBeginning);
  mem.ReadBuffer(req[1], mem.size);

  //--------------------------------------------------

  //IdUDPClient1.Send('114.114.114.114', 53, req);
  IdUDPClient1.Send(txtDns.Text, 53, req);

  res := IdUDPClient1.ReceiveString();


  //--------------------------------------------------
  //�������
  mem.Clear;

  mem.WriteBuffer(res[1], Length(res));
  mem.Seek(0, soFromBeginning);

  FillChar(tres.Head, SizeOf(tres.Head), 0);
  mem.ReadBuffer(tres.Head, SizeOf(tres.Head));

  tres.Head.QDCOUNT := ntohs(tres.Head.QDCOUNT);
  tres.Head.ANCOUNT := ntohs(tres.Head.ANCOUNT);

  //ʵ����Ҫ�ȶ�������
  if tres.Head.QDCOUNT > 0 then
  begin
    //
    SetLength(tres.Queries, tres.Head.QDCOUNT);

    for i := 0 to tres.Head.QDCOUNT-1 do
    begin
      tres.Queries[i].QNAME := ReadName();
      mem.ReadBuffer(tres.Queries[i].QTYPE, SizeOf(tres.Queries[i].QTYPE));
      mem.ReadBuffer(tres.Queries[i].QCLASS, SizeOf(tres.Queries[i].QCLASS));


      tres.Queries[i].QTYPE := htons(tres.Queries[i].QTYPE);
      tres.Queries[i].QCLASS := htons(tres.Queries[i].QCLASS);

    end;

  end;



  if tres.Head.ANCOUNT > 0 then
  begin //����д�����
    //
    SetLength(tres.Answers, tres.Head.ANCOUNT);
    SetLength(tres.IP, tres.Head.ANCOUNT);

    for i := 0 to tres.Head.ANCOUNT-1 do
    begin
      //tres.Answers[i].RNAME := ReadName();
      //mem.ReadBuffer(tres.Answers[i].RNAME_P, SizeOf(tres.Answers[i].RNAME_P));
      //tres.Answers[i].RNAME := ReadName();
      tres.Answers[i].RNAME := ReadName_raw();

      tres.Answers[i].RNAME := ReadName2(tres.Answers[i].RNAME, 1); //test ֻ����֤�㷨,��Ϊ�еݹ�,ʵ��Ӧ���в�Ҫ��

      mem.ReadBuffer(tres.Answers[i].RTYPE, SizeOf(tres.Answers[i].RTYPE));
      mem.ReadBuffer(tres.Answers[i].RCLASS, SizeOf(tres.Answers[i].RCLASS));
      mem.ReadBuffer(tres.Answers[i].RTTL, SizeOf(tres.Answers[i].RTTL));
      mem.ReadBuffer(tres.Answers[i].RDLENGTH, SizeOf(tres.Answers[i].RDLENGTH));

      tres.Answers[i].RTTL := ntohl(tres.Answers[i].RTTL);
      tres.Answers[i].RDLENGTH := htons(tres.Answers[i].RDLENGTH);

      SetLength(tres.Answers[i].RDATA, tres.Answers[i].RDLENGTH);
      FillChar(tres.Answers[i].RDATA[1], tres.Answers[i].RDLENGTH, 0);
      mem.ReadBuffer(tres.Answers[i].RDATA[1], tres.Answers[i].RDLENGTH); //����е�����,ҪС�� //���� A �� MX ��������Ӧ�þ��� 4 �ֽڻ��� 6 �ֽ�(ipv6�������) ip ////AAAA=0x1c,//IPV6��Դ��¼��

      ip := '';
      tres.Answers[i].RTYPE := ntohs(tres.Answers[i].RTYPE);

      if tres.Answers[i].RTYPE = 5 then //5 �� CNAME
      begin
        for k := 1 to Length(tres.Answers[i].RDATA) do
        begin
          ip := ip + tres.Answers[i].RDATA[k]; //cname ��ʱ����������ı���,�������ֽṹ//ʵ���������滹����ָ��,���� www.baidu.com �ĵ�һ��
        end;

        ip := ReadName2(tres.Answers[i].RDATA, 1); //test ֻ����֤�㷨,��Ϊ�еݹ�,ʵ��Ӧ���в�Ҫ��


      end
      else
      //if tres.Answers[i].RTYPE = 1 then //1 �� A ��¼,�����п����� mx ��¼,����ֱ�ӽ����� ip ����
      begin

        for k := 1 to Length(tres.Answers[i].RDATA) do
        begin
          ip := ip + IntToStr(Byte(tres.Answers[i].RDATA[k]));

          if k < Length(tres.Answers[i].RDATA) then
            ip := ip + '.';
        end;


      end;

      tres.IP[i] := ip;

    end;

  end;


  mem.Free;

  //--------------------------------------------------
  for i := 0 to Length(tres.IP)-1 do
  begin
    Memo1.Lines.Add(tres.ip[i]);
  end;

end;

procedure TForm1.Button2Click(Sender: TObject);
var
  req:string;
  res:string;
  b1:TBits;
  host:string;
  treq:TDnsRequest;
  reqTag:VDnsHead_tag;
  mem:TMemoryStream;
  tres:TDnsResponse; //��Ӧ����
  i,k:Integer;
  ip:string;
  resLen:Integer;
  reqLen:Integer;
  tcpLen:int16;


  //��Ӧ���ж���һ������,�պ����� #0 ��β��,���Կ��Լ�
  function ReadName:string;
  var
    j:Integer;
    c:AnsiChar;
    oldPos:Integer; //��Ϊ�����ֽڱ�ʾָ��Ĳ���,����Ҫ��¼��ǰ��λ��
    offset:uint16;
    tmp:string;
    _count:Integer;
  begin


    Result := '';
    _count := 0;

    while mem.Position < mem.Size do
    begin

      //--------------------------------------------------
      //Ҫ�ȿ����ǲ���ָ��,ָ��Ļ��������ֽڱ�ʾλ��,ͬʱ�ڵ�һ���ֽڵ�ǰ��λΪ11 ��  11000000 (0xC0)(192)
      oldPos := mem.Position;
      mem.Read(c, 1);
      if Byte(c)>=192 then
      begin
        mem.Position := oldPos; //�����ȡֻ����̽�Ե�,����Ҫ�ָ�λ��
        mem.Read(offset, 2);
        //offset := offset and
        offset := ntohs(offset);
        offset := offset - $C000; //0xC000 = 49152

        //OFFSET�ֶ�ָ���������Ϣ��ʼ�����������ײ���ID�ֶεĵ�һ���ֽڣ���ƫ������0 ƫ����ָ���� ID �ֶεĵ�һ���ֽڣ��ȵȡ�
        //��ԭʼ�������� res ����ʼλ��

        tmp := Copy(res, offset+1, Length(res));
        tmp := PAnsiChar(tmp); //����ȫ��Ҫ,#0 ���Ҫȥ�� //��ʵ�����������Ҳ���ܻ���ָ��,����Ҫ�������ֵĻ���Ҫ�õݹ���,��������
        Result := Result + tmp;

        //mem.Position := mem.Position + Length(tmp);

        Break; //ָ��ĸ�ʽ������ʱֻ�������ĩ��,���Ե�����,��Ϊ��ʱ�ͽ�����,�ٶ�ȡһ�� 0 �ǲ��Ե�

        //Exit;
      end
      //--------------------------------------------------
      //��������һ���ֽڵĳ��ȼ��ַ���
      else
      begin
        if c = #0 then Break;

        SetLength(tmp, Byte(c));
        mem.Read(tmp[1], Byte(c));

        if Result<>'' then Result := Result + '.';

        Result := Result + tmp;
      end;

      if mem.Position>=mem.Size  //���ȱ���
      then Break;

      Inc(_count);
      if _count>1000 //��������
      then Break;

    end;//while


    Exit;

    //--------------------------------------------------
    for j := mem.Position to mem.Size-1 do
    begin
      mem.Read(c, 1);

      Result := Result + c;

      if c = #0 then Break;
    end;

    //mem.Position := oldPos;
  end;


  //��Ӧ���ж���һ������,�ɵݹ��,��ȡ��Ҫ�ص���ǰλ��//raw ��ԭʼ�ַ��� //level �ǵݹ�Ĳ��,��ֹ��ѭ��
  function ReadName2(const raw:string; const level:Integer):string;
  var
    j:Integer;
    c:AnsiChar;
    oldPos:Integer; //��Ϊ�����ֽڱ�ʾָ��Ĳ���,����Ҫ��¼��ǰ��λ��
    offset:uint16;
    tmp:string;
    _count:Integer;
    fmem:TMemoryStream;
  begin
    Result := '';

    //if level > 1 then Exit; //�ݹ��α���
    if level > 9 then Exit; //�ݹ��α���

    fmem := TMemoryStream.Create;
    //fmem.WriteBuffer(res[1], Length(res));
    fmem.WriteBuffer(raw[1], Length(raw));
    fmem.Seek(0, soFromBeginning);

    //--------------------------------------------------

    Result := '';
    _count := 0;

    while fmem.Position < fmem.Size do
    begin

      //--------------------------------------------------
      //Ҫ�ȿ����ǲ���ָ��,ָ��Ļ��������ֽڱ�ʾλ��,ͬʱ�ڵ�һ���ֽڵ�ǰ��λΪ11 ��  11000000 (0xC0)(192)
      oldPos := fmem.Position;
      fmem.Read(c, 1);
      if Byte(c)>=192 then
      begin
        fmem.Position := oldPos; //�����ȡֻ����̽�Ե�,����Ҫ�ָ�λ��
        fmem.Read(offset, 2);

        offset := ntohs(offset);
        offset := offset - $C000; //0xC000 = 49152

        //OFFSET�ֶ�ָ���������Ϣ��ʼ�����������ײ���ID�ֶεĵ�һ���ֽڣ���ƫ������0 ƫ����ָ���� ID �ֶεĵ�һ���ֽڣ��ȵȡ�
        //��ԭʼ�������� res ����ʼλ��

        tmp := Copy(res, offset+1, Length(res));
        ////tmp := PAnsiChar(tmp); //����ȫ��Ҫ,#0 ���Ҫȥ�� //��ʵ�����������Ҳ���ܻ���ָ��,����Ҫ�������ֵĻ���Ҫ�õݹ���,��������

        tmp := ReadName2(tmp, level + 1);//�������㷨Ӧ�õݹ�

        if Result<>'' then Result := Result + '.';

        Result := Result + tmp;

        //fmem.Position := fmem.Position + Length(tmp);

        Break; //ָ��ĸ�ʽ������ʱֻ�������ĩ��,���Ե�����,��Ϊ��ʱ�ͽ�����,�ٶ�ȡһ�� 0 �ǲ��Ե�

        //Exit;
      end
      //--------------------------------------------------
      //��������һ���ֽڵĳ��ȼ��ַ���
      else
      begin
        if c = #0 then Break;

        SetLength(tmp, Byte(c));
        fmem.Read(tmp[1], Byte(c));

        if Result<>'' then Result := Result + '.';

        Result := Result + tmp;
      end;

      if fmem.Position>=fmem.Size  //���ȱ���
      then Break;

      Inc(_count);
      if _count>1000 //��������
      then Break;

    end;//while


    fmem.Free;

  end;

  //��Ӧ���ж���ԭʼ�ַ���
  function ReadName_raw:string;
  var
    j:Integer;
    c:AnsiChar;
    oldPos:Integer; //��Ϊ�����ֽڱ�ʾָ��Ĳ���,����Ҫ��¼��ǰ��λ��
    offset:uint16;
    tmp:string;
    _count:Integer;
  begin


    Result := '';
    _count := 0;

    while mem.Position < mem.Size do
    begin

      //--------------------------------------------------
      //Ҫ�ȿ����ǲ���ָ��,ָ��Ļ��������ֽڱ�ʾλ��,ͬʱ�ڵ�һ���ֽڵ�ǰ��λΪ11 ��  11000000 (0xC0)(192)
      oldPos := mem.Position;
      mem.Read(c, 1);
      if Byte(c)>=192 then
      begin
        mem.Position := oldPos; //�����ȡֻ����̽�Ե�,����Ҫ�ָ�λ��
        //mem.Read(offset, 2);
        SetLength(tmp, 2);
        mem.Read(tmp[1], 2);


        Result := Result + tmp;

        //mem.Position := mem.Position + Length(tmp);

        Break; //ָ��ĸ�ʽ������ʱֻ�������ĩ��,���Ե�����,��Ϊ��ʱ�ͽ�����,�ٶ�ȡһ�� 0 �ǲ��Ե�

        //Exit;
      end
      //--------------------------------------------------
      //��������һ���ֽڵĳ��ȼ��ַ���
      else
      begin
        Result := Result + c;
        if c = #0 then Break;

        SetLength(tmp, Byte(c));
        mem.Read(tmp[1], Byte(c));

        //if Result<>'' then Result := Result + '.';

        Result := Result + tmp;
      end;

      if mem.Position>=mem.Size  //���ȱ���
      then Break;

      Inc(_count);
      if _count>1000 //��������
      then Break;

    end;//while

  end;


begin

  req := '';
  res := '';

  host := 'www.baidu.com';
  //host := 'lib.csdn.net';
  host := Edit1.Text;

  host := GetHostPack(host);

  treq.Query.QNAME := host;
  treq.Query.QTYPE := htons(1);//$f; // A=0x01, MX=0x0F,
  ////treq.QTYPE := htons($f);//$f; // A=0x01, MX=0x0F,
  treq.Query.QCLASS := htons(1); // internet

  FillChar(treq.Head, SizeOf(treq.Head), 0);
  Randomize();
  treq.Head.ID := Trunc((Now - Trunc(Now)) * 100000) + Random(10000);
  treq.Head.QDCOUNT := htons(1);//1;  //һ������

  //treq.Head.Tag;

  //--------------------------------------------------
  FillChar(reqTag, SizeOf(reqTag), 0);
  reqTag.QR := 0; //1Ϊ��Ӧ��0Ϊ��ѯ��
  reqTag.RD := 1; //ϣ���õ��ݹ�ش�//ֻ�����ſ���Ϊ 1,����ʵ���� Flags ��������˵�����ǹ̶���,����Ҫλ������

  ////
  treq.Head.Flags := htons($100);//0;
  //treq.Head.Flags := 0; //����ûӰ�� //ʵ���� Flags ��������˵�����ǹ̶���,����Ҫλ������//������
  //--------------------------------------------------

  mem := TMemoryStream.Create;

  //mem.WriteBuffer('aaa'[1], 3);
  mem.WriteBuffer(tcpLen, SizeOf(tcpLen)); //tcp Ҫ��д���ֽڵĳ���
  mem.WriteBuffer(treq.Head, SizeOf(treq.Head));
  //ShowMessage(IntToStr(Length(treq.QNAME)));
  mem.WriteBuffer(treq.Query.QNAME[1], Length(treq.Query.QNAME));
  mem.WriteBuffer(treq.Query.QTYPE, SizeOf(treq.Query.QTYPE));
  mem.WriteBuffer(treq.Query.QCLASS, SizeOf(treq.Query.QCLASS));

  tcpLen := mem.Size - 2;              //tcp Ҫ��д���ֽڵĳ���
  tcpLen := htons(tcpLen);             //tcp Ҫ��д���ֽڵĳ���
  mem.Seek(0, soFromBeginning);     //tcp Ҫ��д���ֽڵĳ���
  mem.WriteBuffer(tcpLen, SizeOf(tcpLen)); //tcp Ҫ��д���ֽڵĳ���

  SetLength(req, mem.size);
  mem.Seek(0, soFromBeginning);
  mem.ReadBuffer(req[1], mem.size);

  //--------------------------------------------------

  ////IdUDPClient1.Send('114.114.114.114', 53, req);
  ////res := IdUDPClient1.ReceiveString();

  //reqLen := IdUDPClient1.Send(txtDns.Text, 53, req);
  IdTCPClient1.Host := txtDns.Text;
  IdTCPClient1.Port := 53;
  IdTCPClient1.Disconnect;
  IdTCPClient1.Connect(10*1000);
  reqLen := IdTCPClient1.Socket.Send(req[1], Length(req));
  Memo1.Lines.Add(IntToStr(reqLen));
  res := ''; SetLength(res, 4096);
  //Sleep(5*1000);
  if IdTCPClient1.Socket.Readable(5*1000) = False then
  begin
    Memo1.Lines.Add('read error');
    Exit;
  end;  
  resLen := IdTCPClient1.Socket.Recv(res[1], Length(res));
  SetLength(res, resLen);
  Memo1.Lines.Add(IntToStr(resLen));




  //--------------------------------------------------
  //�������
  mem.Clear;

  res := Copy(res, 1+2, Length(res));  //mem.WriteBuffer(tcpLen, SizeOf(tcpLen)); //tcp Ҫ��д���ֽڵĳ���//��������,��Ϊ��Ҫ������ָ��ƫ����,����Ӧ��ֱ�Ӽ���ԭʼ�ַ�����


  mem.WriteBuffer(res[1], Length(res));
  mem.Seek(0, soFromBeginning);

  //mem.WriteBuffer(tcpLen, SizeOf(tcpLen)); //tcp Ҫ��д���ֽڵĳ���//��������,��Ϊ��Ҫ������ָ��ƫ����,����Ӧ��ֱ�Ӽ���ԭʼ�ַ�����

  FillChar(tres.Head, SizeOf(tres.Head), 0);
  mem.ReadBuffer(tres.Head, SizeOf(tres.Head));

  tres.Head.QDCOUNT := ntohs(tres.Head.QDCOUNT);
  tres.Head.ANCOUNT := ntohs(tres.Head.ANCOUNT);

  //ʵ����Ҫ�ȶ�������
  if tres.Head.QDCOUNT > 0 then
  begin
    //
    SetLength(tres.Queries, tres.Head.QDCOUNT);

    for i := 0 to tres.Head.QDCOUNT-1 do
    begin
      tres.Queries[i].QNAME := ReadName();
      mem.ReadBuffer(tres.Queries[i].QTYPE, SizeOf(tres.Queries[i].QTYPE));
      mem.ReadBuffer(tres.Queries[i].QCLASS, SizeOf(tres.Queries[i].QCLASS));


      tres.Queries[i].QTYPE := htons(tres.Queries[i].QTYPE);
      tres.Queries[i].QCLASS := htons(tres.Queries[i].QCLASS);

    end;

  end;



  if tres.Head.ANCOUNT > 0 then
  begin //����д�����
    //
    SetLength(tres.Answers, tres.Head.ANCOUNT);
    SetLength(tres.IP, tres.Head.ANCOUNT);

    for i := 0 to tres.Head.ANCOUNT-1 do
    begin
      //tres.Answers[i].RNAME := ReadName();
      //mem.ReadBuffer(tres.Answers[i].RNAME_P, SizeOf(tres.Answers[i].RNAME_P));
      //tres.Answers[i].RNAME := ReadName();
      tres.Answers[i].RNAME := ReadName_raw();

      tres.Answers[i].RNAME := ReadName2(tres.Answers[i].RNAME, 1); //test ֻ����֤�㷨,��Ϊ�еݹ�,ʵ��Ӧ���в�Ҫ��

      mem.ReadBuffer(tres.Answers[i].RTYPE, SizeOf(tres.Answers[i].RTYPE));
      mem.ReadBuffer(tres.Answers[i].RCLASS, SizeOf(tres.Answers[i].RCLASS));
      mem.ReadBuffer(tres.Answers[i].RTTL, SizeOf(tres.Answers[i].RTTL));
      mem.ReadBuffer(tres.Answers[i].RDLENGTH, SizeOf(tres.Answers[i].RDLENGTH));

      tres.Answers[i].RTTL := ntohl(tres.Answers[i].RTTL);
      tres.Answers[i].RDLENGTH := htons(tres.Answers[i].RDLENGTH);

      SetLength(tres.Answers[i].RDATA, tres.Answers[i].RDLENGTH);
      FillChar(tres.Answers[i].RDATA[1], tres.Answers[i].RDLENGTH, 0);
      mem.ReadBuffer(tres.Answers[i].RDATA[1], tres.Answers[i].RDLENGTH); //����е�����,ҪС�� //���� A �� MX ��������Ӧ�þ��� 4 �ֽڻ��� 6 �ֽ�(ipv6�������) ip ////AAAA=0x1c,//IPV6��Դ��¼��

      ip := '';
      tres.Answers[i].RTYPE := ntohs(tres.Answers[i].RTYPE);

      if tres.Answers[i].RTYPE = 5 then //5 �� CNAME
      begin
        for k := 1 to Length(tres.Answers[i].RDATA) do
        begin
          ip := ip + tres.Answers[i].RDATA[k]; //cname ��ʱ����������ı���,�������ֽṹ//ʵ���������滹����ָ��,���� www.baidu.com �ĵ�һ��
        end;

        ip := ReadName2(tres.Answers[i].RDATA, 1); //test ֻ����֤�㷨,��Ϊ�еݹ�,ʵ��Ӧ���в�Ҫ��


      end
      else
      //if tres.Answers[i].RTYPE = 1 then //1 �� A ��¼,�����п����� mx ��¼,����ֱ�ӽ����� ip ����
      begin

        for k := 1 to Length(tres.Answers[i].RDATA) do
        begin
          ip := ip + IntToStr(Byte(tres.Answers[i].RDATA[k]));

          if k < Length(tres.Answers[i].RDATA) then
            ip := ip + '.';
        end;


      end;

      tres.IP[i] := ip;

    end;

  end;


  mem.Free;

  //--------------------------------------------------
  for i := 0 to Length(tres.IP)-1 do
  begin
    Memo1.Lines.Add(tres.ip[i]);
  end;


end;

end.













