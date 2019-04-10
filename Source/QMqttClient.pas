/// <summary>
/// <para>
/// MQTT ��Ϣ���пͻ���ʵ�֣� <br />ʹ�÷����� <br />1������һ�� TQMQTTMessageClient
/// ʵ����Ҳ����ֱ����ȫ�ֵ� DefaultMQTTClient ʵ���� <br />2������ RegisterDispatch
/// ���������봦����֮��Ĺ�ϵ�� <br />3������ Subscribe
/// ������Ӷ��ģ�ע���������û�����ӣ��򲻻�ʵ��ע�ᣬ���������Ӻ���Զ�ע�ᡣ <br />4������ Start �����ͻ��ˡ� <br />
/// 5��Ҫ�������⣬���� Publish �������� <br />6��ֹͣ���ӿ��Ե��� Stop ������
/// </para>
/// <para>
/// �����Ϲ�أ���Դ��ѣ�����Ҫ������Ȩ�������е�����ʹ�ñ�����������κκ����
/// </para>
/// </summary>
unit QMqttClient;

interface

{ Ҫ�Զ���¼��־�������ô�ѡ�����Ԫ���͵���־������QMQTT����Ա���д��ʱ���Զ���д�뵽һ���ض�����־�ļ��� }
{ .$DEFINE LogMqttContent }
{$DEFINE EnableSSLMqtt }

uses classes, sysutils, windows, messages, winsock, qstring,
  netencoding, generics.collections, syncobjs, variants, ExtCtrls,
  RegularExpressionsCore{$IFDEF LogMqttContent},
  qlog{$ENDIF}{$IFDEF EnableSSLMqtt}, qdac_ssl{$ENDIF};

const
  /// <summary>
  /// ����ʧ��
  /// </summary>
  MQERR_CONNECT = 0;
  /// <summary>
  /// Э��汾����
  /// </summary>
  MQERR_PROTOCOL_VERSION = 1;
  /// <summary>
  /// �ͻ���ID���ܾ�
  /// </summary>
  MQERR_CLIENT_ID_REJECT = 2;
  /// <summary>
  /// ������������
  /// </summary>
  MQERR_SERVER_UNUSED = 3;
  /// <summary>
  /// ��֤ʧ��
  /// </summary>
  MQERR_BAD_AUTH = 4;
  /// <summary>
  /// ��Ȩ����
  /// </summary>
  MQERR_NO_AUTH = 5;
  /// <summary>
  /// ����ʧ��
  /// </summary>
  MQERR_SUBSCRIBE_FAILED = 20;

  // ����ID����
  MP_PAYLOAD_FORMAT = 1;
  MP_MESSAGE_EXPIRE = 2;
  MP_CONTENT_TYPE = 3;
  MP_RESPONSE_TOPIC = 8;
  MP_DATA = 9;
  MP_ID = 11;
  MP_SESSION_EXPIRE = 17;
  MP_CLIENT_ID = 18;
  MP_KEEP_ALIVE = 19;
  MP_AUTH_METHOD = 21;
  MP_AUTH_DATA = 22;
  MP_NEED_PROBLEM_INFO = 23;
  MP_WILL_DELAY = 24;
  MP_NEED_RESPONSE_INFO = 24;
  MP_RESPONSE_INFO = 26;
  MP_REASON = 31;
  MP_RECV_MAX = 33;
  MP_ALIAS_MAX = 34;
  MP_TOPIC_ALIAS = 35;
  MP_MAX_QOS = 36;
  MP_HAS_RETAIN = 37;
  MP_USER_PROP = 38;
  MP_MAX_PACKAGE_SIZE = 39;
  MP_HAS_WILDCARD_SUBSCRIBES = 40;
  MP_HAS_SUBSCRIBE_ID = 41;
  MP_HAS_SHARE_SUBSCRIBES = 42;

type

  /// <summary>
  /// �������ͣ��ͻ���ֻʹ�ò��֣�����ο� MQTT Э���׼
  /// </summary>
  TQMQTTControlType = (
    /// <summary>
    /// ����δ��
    /// </summary>
    ctReserved,
    /// <summary>
    /// �ͻ���-&gt;���������������ӵ�����������
    /// </summary>
    ctConnect,
    /// <summary>
    /// ������-&gt;�ͻ��ˣ����ӽ��ȷ��
    /// </summary>
    ctConnectAck,
    /// <summary>
    /// ������-&gt;�����ߣ�����һ������Ϣ
    /// </summary>
    ctPublish,
    /// <summary>
    /// ������&lt;-&gt;�����ߣ������յ�����Ϣȷ��
    /// </summary>
    ctPublishAck,
    /// <summary>
    /// ������-&gt;�����ߣ��յ�����
    /// </summary>
    ctPublishRecv,
    /// <summary>
    /// ������-&gt;�����ߣ������ͷ�
    /// </summary>
    ctPublishRelease,
    /// <summary>
    /// ������-&gt;�����ߣ��������
    /// </summary>
    ctPublishDone,
    /// <summary>
    /// �ͻ���-&gt;������������һ�����⣬ע�� QoS ������ܻή��Ϊ������֧�ֵļ���
    /// </summary>
    ctSubscribe,
    /// <summary>
    /// ������-&gt;�ͻ��ˣ����Ľ��֪ͨ
    /// </summary>
    ctSubscribeAck,
    /// <summary>
    /// �ͻ���-&gt;��������ȡ������
    /// </summary>
    ctUnsubscribe,
    /// <summary>
    /// ������-&gt;�ͻ��ˣ�ȡ�����Ľ��ȷ��
    /// </summary>
    ctUnsubscribeAck,
    /// <summary>
    /// �ͻ���-&gt;�����������ͱ���ָ��
    /// </summary>
    ctPing,
    /// <summary>
    /// ������-&gt;�ͻ��ˣ�����ָ��ظ�
    /// </summary>
    ctPingResp,
    /// <summary>
    /// �ͻ���-&gt;���������Ͽ�����
    /// </summary>
    ctDisconnect);
  /// <summary>
  /// MQTT Э��ı�־λ
  /// </summary>
  TQMQTTFlag = (
    /// <summary>
    /// Retain
    /// ��־λ�����ڷ�����Ϣʱ��ȷ����Ϣ�Ƿ�������������Ϣ�ᱻ���沢���µ�ͬ����Ϣ�滻��һ�����¶����߽��룬������Ϣ�����͸��µĶ����ߡ�����ο�
    /// MQTT Э��3.3.1��
    /// </summary>
    mfRetain,
    /// <summary>
    /// �ط���־
    /// </summary>
    mfDup);
  /// <summary>
  /// MQTT ���������ȼ�
  /// </summary>
  TQMQTTQoSLevel = (
    /// <summary>
    /// �����ɷַ�һ�Σ����ն�����ڽ��չ����г���Ҳ�����ط�
    /// </summary>
    qlMax1,
    /// <summary>
    /// ������ɷַ�һ�Σ����ڴ󲿷���Ҫ��֤���յ�����Ϣ��˵����������㹻
    /// </summary>
    qlAtLeast1,
    /// <summary>
    /// ��֤�����ֻ����һ�ηַ�
    /// </summary>
    qlOnly1);
  TQMQTTFlags = set of TQMQTTFlag;

  PQMQTTMessage = ^TQMQTTMessage;

  /// <summary>
  /// �ڲ���Ϣ��ת״̬
  /// </summary>
  TQMQTMessageState = (msSending, msSent, msRecving, msRecved, msDispatching, msDispatched, msNeedWait, msWaiting);
  TQMQTMessageStates = set of TQMQTMessageState;
  TQMQTTMessageClient = class;

  // �����ɷ�ȫ���ŵ����̣߳��ϲ㲻��Ҫ�����̰߳�ȫ
  /// <summary>
  /// ���Ľ��֪ͨ��Ŀ����
  /// </summary>
  TQMQTTSubscribeResult = record
    /// <summary>
    /// ��������
    /// </summary>
    Topic: String;
    /// <summary>
    /// �������
    /// </summary>
    ErrorCode: Byte;
    /// <summary>
    /// ���������ص�����ʵ�ʵ� QoS ����
    /// </summary>
    Qos: TQMQTTQoSLevel;
    function GetSuccess: Boolean;
    property Success: Boolean read GetSuccess;
  end;

  TQMQTTSubscribeResults = array of TQMQTTSubscribeResult;
  PQMQTTSubscribeResults = ^TQMQTTSubscribeResults;

  /// <summary>
  /// ���Ľ��֪ͨ�¼�
  /// </summary>
  TQMQTTTopicSubscribeResultNotify = procedure(ASender: TQMQTTMessageClient; const AResults: TQMQTTSubscribeResults) of object;
  /// <summary>
  /// ȡ�����Ľ��֪ͨ�¼�
  /// </summary>
  TQMQTTTopicUnsubscribeEvent = procedure(ASender: TQMQTTMessageClient; const ATopic: String) of object;
  /// <summary>
  /// ��Ϣ�ɷ��¼���ATopic ָ���˱��ɷ�����Ϣ���⣬��Ȼ��Ҳ���Դ� AReq ������ȡ�� TopicName ���Ե�ֵ������ ATopic
  /// �Ǵ� AReq.TopicName �����ֵ��
  /// </summary>
  TQMQTTTopicDispatchEvent = procedure(ASender: TQMQTTMessageClient; const ATopic: String; const AReq: PQMQTTMessage) of object;
  TQMQTTTopicDispatchEventG = procedure(ASender: TQMQTTMessageClient; const ATopic: String; const AReq: PQMQTTMessage);
  TQMQTTTopicDispatchEventA = reference to procedure(ASender: TQMQTTMessageClient; const ATopic: String;
    const AReq: PQMQTTMessage);
  /// <summary>
  /// ϵͳ����ʱ�Ĵ����¼�
  /// </summary>
  TQMQTTErrorEvent = procedure(ASender: TQMQTTMessageClient; const AErrorCode: Integer; const AErrorMsg: String) of object;
  /// <summary>
  /// ����֪ͨ�¼�
  /// </summary>
  TQMQTTNotifyEvent = procedure(ASender: TQMQTTMessageClient) of object;
  /// <summary>
  /// ��Ϣ֪ͨ�¼�
  /// </summary>
  TQMQTTMessageNotifyEvent = procedure(const AMessage: PQMQTTMessage) of object;

  /// <summary>
  /// MQTT ������Ϣʵ��
  /// </summary>
  TQMQTTMessage = record
  private
    FData: TBytes;
    FCurrent: PByte;
    FVarHeader: PByte;
    FStates: TQMQTMessageStates;
    FClient: TQMQTTMessageClient;
    FAfterSent: TQMQTTMessageNotifyEvent;
    FRecvTime, FSentTime, FSentTimes, FSize: Cardinal;
    // ���ڷ��Ͷ��У��ڲ�ʹ��
    FNext: PQMQTTMessage;
    FWaitEvent: TEvent;
    function GetControlType: TQMQTTControlType;
    procedure SetControlType(const AType: TQMQTTControlType);
    function GetHeaderFlags(const Index: Integer): Boolean;
    procedure SetHeaderFlags(const Index: Integer; const Value: Boolean);
    function GetPayloadSize: Cardinal;
    procedure SetPayloadSize(Value: Cardinal);
    procedure EncodeInt(var ABuf: PByte; V: Cardinal);
    procedure EncodeInt64(var ABuf: PByte; V: UInt64);
    function DecodeInt(var ABuf: PByte; AMaxCount: Integer; var AResult: Cardinal): Boolean;
    function DecodeInt64(var ABuf: PByte; AMaxCount: Integer; var AResult: Int64): Boolean;
    function GetBof: PByte;
    function GetEof: PByte;
    function GetPosition: Integer;
    procedure SetQosLevel(ALevel: TQMQTTQoSLevel);
    function GetQoSLevel: TQMQTTQoSLevel;
    procedure SetPosition(const Value: Integer);
    function GetByte(const AIndex: Integer): Byte;
    procedure SetByte(const AIndex: Integer; const Value: Byte);
    function GetVarHeaderOffset: Integer;
    function GetRemainSize: Integer;
    function GetTopicText: String;
    function GetTopicId: Word;
    function GetTopicContent: TBytes;
    function GetCapacity: Cardinal;
    procedure SetCapacity(const Value: Cardinal);
    function GetTopicName: String;
    function ReloadSize(AKnownBytes: Integer): Boolean;
    function GetTopicContentSize: Integer;
    function GetTopicOriginContent: PByte;
    property Next: PQMQTTMessage read FNext write FNext;
  public
    class function IntEncodedSize(const V: Cardinal): Byte; static;
    /// <summary>
    /// ����һ���µ���Ϣ��������Ҫ���е��� Dispose �ͷ�
    /// </summary>
    function Copy: PQMQTTMessage;
    /// <summary>
    /// ��������ʼ��һ���µ���Ϣʵ��
    /// </summary>
    class function Create(AClient: TQMQTTMessageClient): PQMQTTMessage; static;
    /// <summary>
    /// ��ǰλ��д��һ���ַ���
    /// </summary>
    function Cat(const S: QStringW; AWriteZeroLen: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ���ַ���
    /// </summary>
    function Cat(const S: QStringA; AWriteZeroLen: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��ָ��������
    /// </summary>
    function Cat(const ABuf: Pointer; const ALen: Cardinal): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��ָ��������
    /// </summary>
    function Cat(const ABytes: TBytes): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��8λ�޷�������
    /// </summary>
    function Cat(const V: Byte): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��16λ�޷�������
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: Word; AEncode: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��32λ�޷�������
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: Cardinal; AEncode: Boolean = false): PQMQTTMessage; overload;

    /// <summary>
    /// ��ǰλ��д��һ��64λ�޷�������
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: UInt64; AEncode: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��8λ����
    /// </summary>
    function Cat(const V: Shortint): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��16λ����
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: Smallint; AEncode: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��32λ����
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: Integer; AEncode: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��64λ����
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: Int64; AEncode: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��32λ������
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: Single; AEncode: Boolean = false): PQMQTTMessage; overload;
    /// <summary>
    /// ��ǰλ��д��һ��64λ������
    /// </summary>
    /// <param name="V">
    /// Ҫд�����ֵ
    /// </param>
    /// <param name="AEncode">
    /// �Ƿ������б��루����������ο� EncodeInt �� EncodeInt64 ��ʵ�֣�
    /// </param>
    function Cat(const V: Double; AEncode: Boolean = false): PQMQTTMessage; overload;

    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ���ֽڵ�ֵ��8λ�޷���������
    /// </summary>
    function NextByte: Byte;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ��16λ�޷�������
    /// </summary>
    /// <param name="AIsEncoded">
    /// �Ƿ��Ǳ��������ֵ
    /// </param>
    function NextWord(AIsEncoded: Boolean): Word;

    /// <summary>
    /// ��ȡ��һ��32λ�޷�������
    /// </summary>
    /// <param name="AIsEncoded">
    /// �ӵ�ǰλ���Ƿ��Ǳ��������ֵ
    /// </param>
    function NextDWord(AIsEncoded: Boolean = false): Cardinal;
    /// <summary>
    /// ��ȡ��һ��64λ�޷�������
    /// </summary>
    /// <param name="AIsEncoded">
    /// �Ƿ��Ǳ��������ֵ
    /// </param>
    function NextUInt64(AIsEncoded: Boolean = false): UInt64;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ��8λ����
    /// </summary>
    function NextTinyInt: Shortint;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ��16λ����
    /// </summary>
    /// <param name="AIsEncoded">
    /// �Ƿ��Ǳ��������ֵ
    /// </param>
    function NextSmallInt(AIsEncoded: Boolean = false): Smallint;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ��32λ����
    /// </summary>
    /// <param name="AIsEncoded">
    /// �Ƿ��Ǳ��������ֵ
    /// </param>
    function NextInt(AIsEncoded: Boolean = false): Integer;

    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ��64λ����
    /// </summary>
    /// <param name="AIsEncoded">
    /// �Ƿ��Ǳ��������ֵ
    /// </param>
    function NextInt64(AIsEncoded: Boolean = false): Int64;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ��32λ������
    /// </summary>
    /// <param name="AIsEncoded">
    /// �Ƿ��Ǳ��������ֵ
    /// </param>
    function NextSingle(AIsEncoded: Boolean = false): Single;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡ��һ��64λ������
    /// </summary>
    /// <param name="AIsEncoded">
    /// �Ƿ��Ǳ��������ֵ
    /// </param>
    function NextFloat(AIsEncoded: Boolean = false): Double;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡָ�����ȵ�����
    /// </summary>
    function NextBytes(ASize: Integer): TBytes; overload;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡָ�����ȵ�����
    /// </summary>
    function NextBytes(ABuf: Pointer; ALen: Integer): Integer; overload;
    /// <summary>
    /// �ӵ�ǰλ�ö�ȡһ���ַ���
    /// </summary>
    function NextString: String;

    /// <summary>
    /// ��ǰ������ƶ�ָ����λ�á�����������λ��С��Bof��������ΪBof���������Eof��������ΪEof��ֵ��
    /// </summary>
    function MoveBy(const ADelta: Integer): PQMQTTMessage; inline;
    procedure MoveToVarHeader;
    /// <summary>
    /// ������������
    /// </summary>
    property ControlType: TQMQTTControlType read GetControlType write SetControlType;
    /// <summary>
    /// ��ʮ��������ͼ��ʽ����ʾ������Ϣ���ݣ����ڼ�¼��־������
    /// </summary>
    function ContentAsHexText: String;
    /// <summary>
    /// ������־
    /// </summary>
    property IsRetain: Boolean index 0 read GetHeaderFlags write SetHeaderFlags;
    /// <summary>
    /// �ط���־
    /// </summary>
    property IsDup: Boolean index 1 read GetHeaderFlags write SetHeaderFlags;
    /// <summary>
    /// ������������
    /// </summary>
    property QosLevel: TQMQTTQoSLevel read GetQoSLevel write SetQosLevel;
    /// <summary>
    /// �غɴ�С
    /// </summary>
    property PayloadSize: Cardinal read GetPayloadSize write SetPayloadSize;
    /// <summary>
    /// ���ݿ�ʼ��ַ
    /// </summary>
    property Bof: PByte read GetBof;
    /// <summary>
    /// ���� ������ַ
    /// </summary>
    property Eof: PByte read GetEof;
    /// <summary>
    /// ���ݵ�ǰ��ַ
    /// </summary>
    property Current: PByte read FCurrent;
    /// <summary>
    /// �ɱ�ͷ������ʼλ�ã��ǹ̶�ͷ+ʣ�೤�Ⱥ����ʼλ�ã��������ַ��ʼ�Ǹ������Ͳ�ͬ����
    /// </summary>
    property VarHeader: PByte read FVarHeader;
    /// <summary>
    /// �ɱ�ͷ����ƫ����
    /// </summary>
    property VarHeaderOffset: Integer read GetVarHeaderOffset;
    /// <summary>
    /// ��ǰλ��
    /// </summary>
    property Position: Integer read GetPosition write SetPosition;
    /// <summary>
    /// ������Ϣ���ݳ��ȣ�ע����С�ڵ��� Capacity ���Ե�ֵ��
    /// </summary>
    property Size: Cardinal read FSize;
    /// <summary>
    /// ʣ���С������ Size-Position
    /// </summary>
    property RemainSize: Integer read GetRemainSize;
    /// <summary>
    /// �������ض��ֽڵ�ֵ
    /// </summary>
    property Bytes[const AIndex: Integer]: Byte read GetByte write SetByte; default;
    /// <summary>
    /// ��ǰ״̬
    /// </summary>
    property States: TQMQTMessageStates read FStates write FStates;
    /// <summary>
    /// ��Ϣ������ TQMQTTMessageClient ʵ��
    /// </summary>
    property Client: TQMQTTMessageClient read FClient write FClient;
    /// <summary>
    /// ���ջ��͵���Ϣ��PackageId�����Բ������͵���Ϣ��Ч����Ч�����ͷ��� 0
    /// </summary>
    property TopicId: Word read GetTopicId;
    /// <summary>
    /// ��Ϣ���⣬��������Ϊ ctPublish ʱ������
    /// </summary>
    property TopicName: String read GetTopicName;
    /// <summary>
    /// ��Ϣ���ı����ݣ�ע��������ȷ����Ϣ���ı���ʽ�����ݣ�������ܳ����쳣���޷������ݵ��� UTF-8 ������ַ���������
    /// </summary>
    property TopicText: String read GetTopicText;
    /// <summary>
    /// ��Ϣ��Ķ���������
    /// </summary>
    property TopicContent: TBytes read GetTopicContent;
    /// <summary>
    /// ���յ�����Ϣ�����ܴ�С��ע��� Size �����𣩣�����������Ϣ������������ռ�õĿռ�
    /// </summary>
    property TopicContentSize: Integer read GetTopicContentSize;
    /// <summary>
    /// ��Ϣ��ԭʼ���ݵ�ַ
    /// </summary>
    property TopicOriginContent: PByte read GetTopicOriginContent;
    /// <summary>
    /// ������С
    /// </summary>
    property Capacity: Cardinal read GetCapacity write SetCapacity;
  end;

  /// <summary>
  /// ����ƥ��ģʽ
  /// </summary>
  TTopicMatchType = (
    /// <summary>
    /// ����ƥ�䣨ע����Ϣ�������ִ�Сд��
    /// </summary>
    mtFull,
    /// <summary>
    /// ģʽƥ�䣬֧��ͨ�����$,#+��
    /// </summary>
    mtPattern,
    /// <summary>
    /// ������ʽƥ��
    /// </summary>
    mtRegex);

  /// <summary>
  /// ��Ϣ���������ڲ���¼ʹ�ã����ڼ�¼�û����붩�ĵ���Ϣ����
  /// </summary>
  TQMQTTSubscribeItem = record
    Topic: String;
    Qos: TQMQTTQoSLevel;
  end;

  TQMQTTProtocolVersion = (pv3_1_1 = 4, pv5_0 = 5);
  TQMQTT5AuthMode = (amNone);
  TQMQTT5PropDataType = (ptUnknown, ptByte, ptWord, ptInt, ptVarInt, ptString, ptBinary);

  TQMQTT5PropType = record
  private
    FName: String;
    FId: Byte;
    FDataType: TQMQTT5PropDataType;
    function GetDataSize: Integer;
  public
    property Id: Byte read FId;
    property DataType: TQMQTT5PropDataType read FDataType;
    property DataSize: Integer read GetDataSize;
    property Name: String read FName;
  end;

  PQMQTT5PropType = ^TQMQTT5PropType;

  TQMQTT5Prop = record
    case Integer of
      0:
        (AsByte: Byte);
      1:
        (AsWord: Word);
      2:
        (AsInteger: Cardinal);
      3:
        (AsString: PQStringA; IsSet: Boolean);
      4:
        (AsBytes: ^TBytes);
  end;

  PQMQTT5Prop = ^TQMQTT5Prop;

  TQMQTT5Props = class
  private
    function GetPropTypes(const APropId: Byte): PQMQTT5PropType;
    function GetAsInt(const APropId: Byte): Cardinal;
    function GetAsString(const APropId: Byte): String;
    function GetAsVariant(const APropId: Byte): Variant;
    procedure SetAsInt(const APropId: Byte; const Value: Cardinal);
    procedure SetAsString(const APropId: Byte; const Value: String);
    procedure SetAsVariant(const APropId: Byte; const Value: Variant);
    function GetIsSet(const APropId: Byte): Boolean;
    function GetDataSize(const APropId: Byte): Integer;
    function GetPayloadSize: Integer;
    function GetMinMaxId(const Index: Integer): Byte;
  protected
    FItems: TArray<TQMQTT5Prop>;
  public
    constructor Create;
    destructor Destroy; override;
    function Copy: TQMQTT5Props;
    procedure ReadProps(const AMessage: PQMQTTMessage);
    procedure WriteProps(AMessage: PQMQTTMessage);
    procedure Replace(AProps: TQMQTT5Props);
    property PropTypes[const APropId: Byte]: PQMQTT5PropType read GetPropTypes;
    property Values[const APropId: Byte]: Variant read GetAsVariant write SetAsVariant;
    property AsInt[const APropId: Byte]: Cardinal read GetAsInt write SetAsInt;
    property AsString[const APropId: Byte]: String read GetAsString write SetAsString;
    property IsSet[const APropId: Byte]: Boolean read GetIsSet;
    property DataSize[const APropId: Byte]: Integer read GetDataSize;
    property PayloadSize: Integer read GetPayloadSize;
    property MinId: Byte index 0 read GetMinMaxId;
    property MaxId: Byte index 1 read GetMinMaxId;
  end;

  TQMQTTClientState = (qcsConnecting, qcsReconnecting, qcsRunning, qcsStop);
  TQMQTTClientStates = set of TQMQTTClientState;

  /// <summary>
  /// QMQTT ��Ϣ�ͻ���ʵ�֣�ע��Ŀǰ�汾��û��ʵ����Ϣ���ط�����Ҫ����������
  /// </summary>
  TQMQTTMessageClient = class(TComponent)
  private

  protected
    // �¼��б�
    FBeforeConnect: TQMQTTNotifyEvent;
    FAfterDispatch: TQMQTTTopicDispatchEvent;
    FAfterConnected: TQMQTTNotifyEvent;
    FBeforeDispatch: TQMQTTTopicDispatchEvent;
    FBeforePublish: TQMQTTTopicDispatchEvent;
    FAfterSubscribed: TQMQTTTopicSubscribeResultNotify;
    FAfterUnsubscribed: TQMQTTTopicUnsubscribeEvent;
    FAfterPublished: TQMQTTTopicDispatchEvent;
    FBeforeSubscribe: TQMQTTTopicDispatchEvent;
    FBeforeUnsubscribe: TQMQTTTopicDispatchEvent;
    FBeforeSend: TQMQTTMessageNotifyEvent;
    FAfterSent: TQMQTTMessageNotifyEvent;
    FOnRecvTopic: TQMQTTTopicDispatchEvent;
    FAfterDisconnected: TQMQTTNotifyEvent;
    //

    FConnectionTimeout, FReconnectInterval: Cardinal;
    FServerHost, FUserName, FPassword, FClientId, FWillTopic: String;
    FWillMessage: TBytes;
    FRecvThread, FSendThread: TThread;
    FThreadCount: Integer;
    FSocket: THandle;
    FOnError: TQMQTTErrorEvent;
    FPackageId: Integer;
    FWaitAcks: TArray<PQMQTTMessage>;
    FSubscribes: TStringList;
    FTopicHandlers: TStringList;
    FNotifyEvent: TEvent;
    FLastIoTick: Cardinal;
    FPingStarted: Cardinal;
    FReconnectTimes, FReconnectTime: Cardinal;
    FLastConnectTime: Cardinal;
    FSentTopics: Cardinal;
    FRecvTopics: Cardinal;
    FConnectProps: TQMQTT5Props;
    FTimer: TTimer;
    FStates: TQMQTTClientStates;
    FPeekInterval: Word;
    FServerPort: Word;

    FProtocolVersion: TQMQTTProtocolVersion;
    FQoSLevel: TQMQTTQoSLevel;
    FIsRetain: Boolean;
    FCleanLastSession: Boolean;
    FConnected: Boolean;
{$IFDEF LogMqttContent}
    FLogPackageContent: Boolean;
{$ENDIF}
{$IFDEF EnableSSLMqtt}
    FUseSSL: Boolean;
    FSSL: TQSSLItem;
{$ENDIF}
    procedure RecreateSocket;
    procedure DoConnect;
    procedure DoDispatch(var AReq: TQMQTTMessage);
    procedure DispatchTopic(AMsg: PQMQTTMessage);
    procedure DispatchProps(AMsg: PQMQTTMessage);
    procedure InvokeTopicHandlers(const ATopic: String; AMsg: PQMQTTMessage);
    procedure DoError(AErrorCode: Integer);
    procedure DoBeforeConnect;
    procedure DoAfterConnected;
    procedure DoConnectFailed;
    procedure DoBeforePublish(ATopic: String; AMsg: PQMQTTMessage);
    procedure DoAfterSubcribed(AResult: PQMQTTSubscribeResults);
    procedure DoAfterUnsubscribed(ASource: PQMQTTMessage);
    procedure ValidClientId;
    procedure SetWillMessage(const AValue: TBytes);
    procedure DoBeforeSend(const AReq: PQMQTTMessage);
    procedure DoAfterSent(const AReq: PQMQTTMessage);
    function DoSend(AReq: PQMQTTMessage): Boolean;
    procedure DoRecv;
    function GetClientId: String;
    procedure Lock; inline;
    procedure Unlock; inline;
    procedure ClearWaitAcks;
    procedure ClearHandlers;
    function PopWaitAck(APackageId: Word): PQMQTTMessage;
    function DNSLookupV4(const AHost: QStringW): Cardinal; overload;
    procedure DoFreeAfterSent(const AMessage: PQMQTTMessage);
    procedure DoTopicPublished(const AMessage: PQMQTTMessage);
    procedure Disconnect;
    procedure DoAfterDisconnected;
    procedure DoPing;
    procedure FreeMessage(AMsg: PQMQTTMessage);
    function AcquirePackageId(AReq: PQMQTTMessage; AIsWaitAck: Boolean): Word;
    procedure Queue(ACallback: TThreadProcedure);
    procedure DoCloseSocket;
    function GetIsRunning: Boolean;
    function GetConnectProps: TQMQTT5Props;
{$IFDEF EnableSSLMqtt}
    function GetSSLManager: TQSSLManager;
{$ENDIF}
    procedure DoTimer(ASender: TObject);
    procedure ReconnectNeeded;
    procedure DoCleanup;
  public
    /// <summary>
    /// ���캯��
    /// </summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>
    /// ����ǰ����
    /// </summary>
    procedure BeforeDestruction; override;

    /// <summary>
    /// ��������
    /// </summary>
    destructor Destroy; override;
    /// <summary>
    /// ��������
    /// </summary>
    procedure Start;
    /// <summary>
    /// ֹͣ����
    /// </summary>
    procedure Stop;
    /// <summary>
    /// ���ķ���
    /// </summary>
    /// <param name="ATopics">
    /// �����б�֧��ģʽƥ��
    /// </param>
    /// <param name="AQoS">
    /// ��������Ҫ��
    /// </param>
    /// <param name="AProps">
    /// �����������ã���5.0��Э����Ч��
    /// </param>
    /// <remarks>
    /// 1�� ��������Ҫ�󲢲������յķ�������Ҫ��һ�£���������֧�ָü���ʱ�����ܽ����� <br />
    /// 2�������δ���ӵ������������Ӧ��������ڷ���������ɺ����Զ����ģ�����Ʊ���ϳ������ϳ�����Ʊ�����𣩡�
    /// </remarks>
    procedure Subscribe(const ATopics: array of String; const AQoS: TQMQTTQoSLevel; AProps: TQMQTT5Props = nil);
    /// <summary>
    /// ȡ��ָ�������ⶩ��
    /// </summary>
    /// <param name="ATopics">
    /// Ҫȡ���������б�
    /// </param>
    /// <remarks>
    /// �������ֻ����������ɺ�ſ��ԣ���ʱ��֧������ȡ��
    /// </remarks>
    procedure Unsubscribe(const ATopics: array of String);
    /// <summary>
    /// ����һ����Ϣ
    /// </summary>
    /// <param name="ATopic">
    /// ��Ϣ���⣬ע�ⲻ��ʹ���κ�ͨ���
    /// </param>
    /// <param name="AContent">
    /// ��Ϣ����
    /// </param>
    /// <param name="AQoSLevel">
    /// ��������Ҫ��
    /// </param>
    procedure Publish(const ATopic, AContent: String; AQoSLevel: TQMQTTQoSLevel); overload;
    /// <summary>
    /// ����һ����Ϣ
    /// </summary>
    /// <param name="ATopic">
    /// ��Ϣ���⣬ע�ⲻ��ʹ���κ�ͨ���
    /// </param>
    /// <param name="AContent">
    /// ��Ϣ����
    /// </param>
    /// <param name="AQoSLevel">
    /// ��������Ҫ��
    /// </param>
    procedure Publish(const ATopic: String; AContent: TBytes; AQoSLevel: TQMQTTQoSLevel); overload;
    /// <summary>
    /// ����һ����Ϣ
    /// </summary>
    /// <param name="ATopic">
    /// ��Ϣ���⣬ע�ⲻ��ʹ���κ�ͨ���
    /// </param>
    /// <param name="AContent">
    /// ��Ϣ����
    /// </param>
    /// <param name="AQoSLevel">
    /// ��������Ҫ��
    /// </param>
    procedure Publish(const ATopic: String; const AContent; ALen: Cardinal; AQoSLevel: TQMQTTQoSLevel); overload;

    /// <summary>
    /// ע��һ����Ϣ�ɷ��������
    /// </summary>
    /// <param name="ATopic">
    /// Ҫ���������⣬��ʽ�� AType ����������Ҫ�󱣳�һ��
    /// </param>
    /// <param name="AHandler">
    /// ��Ϣ������
    /// </param>
    /// <param name="AType">
    /// ��Ϣ��������
    /// </param>
    procedure RegisterDispatch(const ATopic: String; AHandler: TQMQTTTopicDispatchEvent;
      AType: TTopicMatchType = mtFull); overload;
    procedure RegisterDispatch(const ATopic: String; AHandler: TQMQTTTopicDispatchEventG;
      AType: TTopicMatchType = mtFull); overload;
    procedure RegisterDispatch(const ATopic: String; AHandler: TQMQTTTopicDispatchEventA;
      AType: TTopicMatchType = mtFull); overload;
    /// <summary>
    /// �Ƴ�һ����Ϣ�ɷ�����ע��
    /// </summary>
    procedure UnregisterDispatch(AHandler: TQMQTTTopicDispatchEvent); overload;

    /// <summary>
    /// ������IP������
    /// </summary>
    property ServerHost: String read FServerHost write FServerHost;
    /// <summary>
    /// �������˿ںţ�Ĭ��1883
    /// </summary>
    property ServerPort: Word read FServerPort write FServerPort;
    /// <summary>
    /// �û���
    /// </summary>
    property UserName: String read FUserName write FUserName;
    /// <summary>
    /// ����
    /// </summary>
    property Password: String read FPassword write FPassword;
    /// <summary>
    /// �ͻ�ID�������ָ����������ɡ���Ȼ������Լ����������ID��
    /// </summary>
    property ClientId: String read GetClientId write FClientId;
    /// <summary>
    /// ���ӳ�ʱ
    /// </summary>
    property ConnectionTimeout: Cardinal read FConnectionTimeout write FConnectionTimeout;
    /// <summary>
    /// Ĭ�Ϸ�������Ҫ��
    /// </summary>
    property QosLevel: TQMQTTQoSLevel read FQoSLevel write FQoSLevel;
    /// <summary>
    /// ���Ե�����
    /// </summary>
    property WillTopic: String read FWillTopic write FWillTopic;
    /// <summary>
    /// ���Ե����ݣ����������ַ�������ʹ�� UTF 8 ����
    /// </summary>
    property WillMessage: TBytes read FWillMessage write SetWillMessage;
    /// <summary>
    /// Ĭ�ϱ�����־
    /// </summary>
    property IsRetain: Boolean read FIsRetain write FIsRetain;
    /// <summary>
    /// �Ƿ�����ʱ����ϴλỰ��Ϣ
    /// </summary>
    property CleanLastSession: Boolean read FCleanLastSession write FCleanLastSession;
    /// <summary>
    /// ����������λΪ��
    /// </summary>
    property PeekInterval: Word read FPeekInterval write FPeekInterval;
    property ReconnectInterval: Cardinal read FReconnectInterval write FReconnectInterval;
    /// <summary>
    /// �ͻ����Ƿ��Ѿ��ɹ����ӵ�������
    /// </summary>
    property IsRunning: Boolean read GetIsRunning;
    property Connected: Boolean read FConnected;
    /// <summary>
    /// ���յ�����Ϣ����
    /// </summary>
    property RecvTopics: Cardinal read FRecvTopics;
    /// <summary>
    /// ���͵���Ϣ����
    /// </summary>
    property SentTopics: Cardinal read FSentTopics;
{$IFDEF LogMqttContent}
    property LogPackageContent: Boolean read FLogPackageContent write FLogPackageContent;
{$ENDIF}
{$IFDEF EnableSSLMqtt}
    property UseSSL: Boolean read FUseSSL write FUseSSL;
    property SSLManager: TQSSLManager read GetSSLManager;
{$ENDIF}
    // MQTT 5.0 Added
    property ProtocolVersion: TQMQTTProtocolVersion read FProtocolVersion write FProtocolVersion;
    property ConnectProps: TQMQTT5Props read GetConnectProps;

    /// <summary>
    /// ����֪ͨ
    /// </summary>
    property OnError: TQMQTTErrorEvent read FOnError write FOnError;
    /// <summary>
    /// ����ǰ֪ͨ
    /// </summary>
    property BeforeConnect: TQMQTTNotifyEvent read FBeforeConnect write FBeforeConnect;
    /// <summary>
    /// ���Ӻ�֪ͨ
    /// </summary>
    property AfterConnected: TQMQTTNotifyEvent read FAfterConnected write FAfterConnected;
    /// <summary>
    /// �Ͽ���֪ͨ
    /// </summary>
    property AfterDisconnected: TQMQTTNotifyEvent read FAfterDisconnected write FAfterDisconnected;
    /// <summary>
    /// �ɷ�ǰ֪ͨ
    /// </summary>
    property BeforeDispatch: TQMQTTTopicDispatchEvent read FBeforeDispatch write FBeforeDispatch;
    /// <summary>
    /// �ɷ���֪ͨ
    /// </summary>
    property AfterDispatch: TQMQTTTopicDispatchEvent read FAfterDispatch write FAfterDispatch;
    /// <summary>
    /// ����ǰ֪ͨ
    /// </summary>
    property BeforePublish: TQMQTTTopicDispatchEvent read FBeforePublish write FBeforePublish;
    /// <summary>
    /// ������֪ͨ
    /// </summary>
    property AfterPublished: TQMQTTTopicDispatchEvent read FAfterPublished write FAfterPublished;
    /// <summary>
    /// ����ǰ֪ͨ
    /// </summary>
    property BeforeSubscribe: TQMQTTTopicDispatchEvent read FBeforeSubscribe write FBeforeSubscribe;
    /// <summary>
    /// ���ĺ�֪ͨ
    /// </summary>
    property AfterSubscribed: TQMQTTTopicSubscribeResultNotify read FAfterSubscribed write FAfterSubscribed;
    /// <summary>
    /// ȡ������ǰ֪ͨ
    /// </summary>
    property BeforeUnsubscribe: TQMQTTTopicDispatchEvent read FBeforeUnsubscribe write FBeforeUnsubscribe;
    /// <summary>
    /// ȡ�����ĺ�֪ͨ
    /// </summary>
    property AfterUnsubscribed: TQMQTTTopicUnsubscribeEvent read FAfterUnsubscribed write FAfterUnsubscribed;
    /// <summary>
    /// ��������ǰ֪ͨ
    /// </summary>
    property BeforeSend: TQMQTTMessageNotifyEvent read FBeforeSend write FBeforeSend;
    /// <summary>
    /// �������ݺ�֪ͨ
    /// </summary>
    property AfterSent: TQMQTTMessageNotifyEvent read FAfterSent write FAfterSent;
    /// <summary>
    /// �յ���Ϣʱ֪ͨ
    /// </summary>
    property OnRecvTopic: TQMQTTTopicDispatchEvent read FOnRecvTopic write FOnRecvTopic;
  end;

  /// <summary>
  /// Ĭ�ϵ�ȫ�� MQTT �ͻ���ʵ��
  /// </summary>
function DefaultMqttClient: TQMQTTMessageClient;

implementation

resourcestring
  STooLargePayload = '�غɴ�С %d ����������';
  SClientNotRunning = '�ͻ���δ���ӵ������������ܶ���';
  SInitSSLFailed = '��ʼ�� SSL ʧ�ܣ�����Ŀ¼���Ƿ���� ssleay32.dll �� libeay32.dll/libssl32.dll';

const
  MQTT5PropTypes: array [0 .. 41] of TQMQTT5PropType = ( //
    (FName: 'PayloadFormat'; FId: 1; FDataType: ptByte), //
    (FName: 'MessageExpire'; FId: 2; FDataType: ptInt), //
    (FName: 'ContentType'; FId: 3; FDataType: ptString), //
    (FName: ''; FId: 4; FDataType: ptUnknown), //
    (FName: ''; FId: 5; FDataType: ptUnknown), //
    (FName: ''; FId: 6; FDataType: ptUnknown), //
    (FName: ''; FId: 7; FDataType: ptUnknown), //
    (FName: 'ResponseTopic'; FId: 8; FDataType: ptString), //
    (FName: 'Data'; FId: 9; FDataType: ptBinary), //
    (FName: ''; FId: 10; FDataType: ptUnknown), //
    (FName: 'Identifier'; FId: 11; FDataType: ptInt), //
    (FName: ''; FId: 12; FDataType: ptUnknown), //
    (FName: ''; FId: 13; FDataType: ptUnknown), //
    (FName: ''; FId: 14; FDataType: ptUnknown), //
    (FName: ''; FId: 15; FDataType: ptUnknown), //
    (FName: ''; FId: 16; FDataType: ptUnknown), //
    (FName: 'SessionExpire'; FId: 17; FDataType: ptInt), //
    (FName: 'AssignClientId'; FId: 18; FDataType: ptString), //
    (FName: 'KeepAlive'; FId: 19; FDataType: ptWord), //
    (FName: ''; FId: 20; FDataType: ptUnknown), //
    (FName: 'AuthMethod'; FId: 21; FDataType: ptString), //
    (FName: 'AuthData'; FId: 22; FDataType: ptBinary), //
    (FName: 'NeedProblemInfo'; FId: 23; FDataType: ptByte), //
    (FName: 'WillDelay'; FId: 24; FDataType: ptInt), //
    (FName: 'NeedRespInfo'; FId: 25; FDataType: ptByte), //
    (FName: 'ResponseInfo'; FId: 26; FDataType: ptString), //
    (FName: ''; FId: 27; FDataType: ptUnknown), //
    (FName: 'ServerRefer'; FId: 28; FDataType: ptString), //
    (FName: ''; FId: 29; FDataType: ptUnknown), //
    (FName: ''; FId: 30; FDataType: ptUnknown), //
    (FName: 'Reason'; FId: 31; FDataType: ptString), //
    (FName: ''; FId: 32; FDataType: ptUnknown), //
    (FName: 'RecvMax'; FId: 33; FDataType: ptWord), //
    (FName: 'AliasMax'; FId: 34; FDataType: ptWord), //
    (FName: 'TopicAlias'; FId: 35; FDataType: ptWord), //
    (FName: 'MaxQoS'; FId: 36; FDataType: ptByte), //
    (FName: 'HasRetain'; FId: 37; FDataType: ptByte), //
    (FName: 'UserProp'; FId: 38; FDataType: ptString), //
    (FName: 'MaxPkgSize'; FId: 39; FDataType: ptInt), //
    (FName: 'HasWildcardSubcribes'; FId: 40; FDataType: ptByte), //
    (FName: 'HasSubscribeId'; FId: 41; FDataType: ptByte), //
    (FName: 'HasShareSubscribes'; FId: 42; FDataType: ptByte) //
    );

type
  TQMQTTConnectHeader = packed record
    Protocol: array [0 .. 5] of Byte;
    Level: Byte; // Level
    Flags: Byte; // Flags
    Interval: Word; // Keep Alive
  end;

  PMQTTConnectHeader = ^TQMQTTConnectHeader;

  TSocketThread = class(TThread)
  protected
    [unsafe]
    FOwner: TQMQTTMessageClient;
  public
    constructor Create(AOwner: TQMQTTMessageClient); overload;
  end;

  TSocketRecvThread = class(TSocketThread)
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TQMQTTMessageClient); overload;
  end;

  TSocketSendThread = class(TSocketThread)
  protected
    FNotifyEvent: TEvent;
    FFirst, FLast: PQMQTTMessage;
    procedure Execute; override;
  public
    constructor Create(AOwner: TQMQTTMessageClient); overload;
    destructor Destroy; override;
    procedure Post(AMessage: PQMQTTMessage);
    procedure Send(AMessage: PQMQTTMessage);
  end;

  TTopicHandler = class
  protected
    FRegex: TPerlRegex;
    FTopic: String;
    FOnDispatch: TQMQTTTopicDispatchEvent;
    FNext: TTopicHandler;
    FMatchType: TTopicMatchType;
  public
    constructor Create(const ATopic: String; AHandler: TQMQTTTopicDispatchEvent; AMatchType: TTopicMatchType);
    destructor Destroy; override;
    function IsMatch(const ATopic: String): Boolean;
  end;

const
  RegexTopic = '@regex@';
  PatternTopic = '@topic@';

var
  _DefaultClient: TQMQTTMessageClient = nil;

function DefaultMqttClient: TQMQTTMessageClient;
var
  AClient: TQMQTTMessageClient;
begin
  if not Assigned(_DefaultClient) then
  begin
    AClient := TQMQTTMessageClient.Create(nil);
    if AtomicCmpExchange(Pointer(_DefaultClient), Pointer(AClient), nil) <> nil then
      FreeAndNil(AClient);
  end;
  Result := _DefaultClient;
end;
{ TMessageQueue }

function TQMQTTMessageClient.AcquirePackageId(AReq: PQMQTTMessage; AIsWaitAck: Boolean): Word;
var
  ALast: Word;
  ATryTimes: Integer;
begin
  ATryTimes := 0;
  repeat
    Lock;
    try
      ALast := FPackageId;
      repeat
        Result := Word(AtomicIncrement(FPackageId));
        if not Assigned(FWaitAcks[Result]) then
        begin
          if AIsWaitAck then
            FWaitAcks[Result] := AReq;
          Break;
        end;
      until Result = ALast;
    finally
      Unlock;
    end;
    if Result = ALast then
    begin
      Result := 0;
      // ����ʱ����ȷ�ճ����õ�PackageId��������Գ���3���Բ��У�����
      // ��������ϴ����ʱ,����Ϊ����������£����Դ�ȷ�ϵ��Ѿ���65536�
      // ������̫����
      Sleep(50);
      Inc(ATryTimes);
    end;
  until (Result > 0) and (ATryTimes < 3);
  // Ͷ�ݵ�̫�࣬��ɵȴ�ȷ�ϵİ��Ѿ��ﵽ���ޣ���ô����
  Assert(Result <> ALast);
end;

procedure TQMQTTMessageClient.BeforeDestruction;
begin
  inherited;
  FTimer.Enabled := false;
  Stop;
end;

procedure TQMQTTMessageClient.ClearHandlers;
var
  I: Integer;
begin
  for I := 0 to FTopicHandlers.Count - 1 do
    FreeObject(FTopicHandlers.Objects[I]);
  FTopicHandlers.Clear;
end;

procedure TQMQTTMessageClient.ClearWaitAcks;
var
  I, C: Integer;
  ATemp: TArray<PQMQTTMessage>;
begin
  SetLength(ATemp, 65536);
  C := 0;
  Lock;
  try
    for I := 0 to High(FWaitAcks) do
    begin
      if Assigned(FWaitAcks[I]) then
      begin
        ATemp[C] := FWaitAcks[I];
        Inc(C);
        FWaitAcks[I] := nil;
      end;
    end;
  finally
    Unlock;
  end;
  for I := 0 to C - 1 do
    FreeMessage(ATemp[I]);
end;

constructor TQMQTTMessageClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPeekInterval := 60;
  FConnectionTimeout := 15000;
  FReconnectInterval := 15;
  FStates := [qcsStop];
  FNotifyEvent := TEvent.Create(nil, false, false, '');
  FTopicHandlers := TStringList.Create;
  FTopicHandlers.Sorted := true;
  FSubscribes := TStringList.Create;
  FSubscribes.Sorted := true;
  FSubscribes.Duplicates := dupIgnore;
  FProtocolVersion := pv3_1_1;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := false;
  FTimer.OnTimer := DoTimer;
end;

destructor TQMQTTMessageClient.Destroy;
var
  I: Integer;
  AProps: TQMQTT5Props;
begin
  FreeAndNil(FTimer);
  FreeAndNil(FNotifyEvent);
  ClearHandlers;
  FreeAndNil(FTopicHandlers);
  for I := 0 to FSubscribes.Count - 1 do
  begin
    AProps := TQMQTT5Props(FSubscribes.Objects[I]);
    if Assigned(AProps) then
      FreeAndNil(AProps);
  end;
  FreeAndNil(FSubscribes);
  FreeAndNil(FConnectProps);
  inherited;
end;

procedure TQMQTTMessageClient.Disconnect;
var
  AReq: PQMQTTMessage;
begin
  if Assigned(FSendThread) then
  begin
    AReq := TQMQTTMessage.Create(Self);
    AReq.PayloadSize := 0;
    AReq.ControlType := TQMQTTControlType.ctDisconnect;
    AReq.FAfterSent := DoFreeAfterSent;
    AReq.States := [msNeedWait];
    TSocketSendThread(FSendThread).Send(AReq);
  end;
end;

procedure TQMQTTMessageClient.InvokeTopicHandlers(

  const ATopic: String; AMsg: PQMQTTMessage);
var
  AIdx: Integer;
  procedure InvokeItem(AItem: TTopicHandler);
  begin
    while Assigned(AItem) do
    begin
      if Assigned(AItem.FOnDispatch) and AItem.IsMatch(ATopic) then
      begin
        case IntPtr(TMethod(AItem.FOnDispatch).Data) of
          0:
            TQMQTTTopicDispatchEventG(TMethod(AItem.FOnDispatch).Code)(Self, ATopic, AMsg);
          1:
            TQMQTTTopicDispatchEventA(TMethod(AItem.FOnDispatch).Code)(Self, ATopic, AMsg);
        else
          AItem.FOnDispatch(Self, ATopic, AMsg);
        end;
      end;
      AItem := AItem.FNext;
    end;
  end;

begin
  if FTopicHandlers.Find(ATopic, AIdx) then
    InvokeItem(TTopicHandler(FTopicHandlers.Objects[AIdx]));
  if FTopicHandlers.Find(PatternTopic, AIdx) then
    InvokeItem(TTopicHandler(FTopicHandlers.Objects[AIdx]));
  if FTopicHandlers.Find(RegexTopic, AIdx) then
    InvokeItem(TTopicHandler(FTopicHandlers.Objects[AIdx]));
end;

procedure TQMQTTMessageClient.DispatchProps(AMsg: PQMQTTMessage);
var
  AProps: TQMQTT5Props;
begin
  if ProtocolVersion = pv5_0 then
  begin
    AProps := TQMQTT5Props.Create;
    try
      AProps.ReadProps(AMsg);
      ConnectProps.Replace(AProps);
    finally
      FreeAndNil(AProps);
    end;
  end;
end;

procedure TQMQTTMessageClient.DispatchTopic(AMsg: PQMQTTMessage);
var
  ACopy: PQMQTTMessage;
begin
  ACopy := AMsg.Copy;
  Queue(
    procedure
    var
      ATopic: String;
    begin
      try
        Inc(FRecvTopics);
        ATopic := ACopy.TopicName;
        if Assigned(FOnRecvTopic) then
          FOnRecvTopic(Self, ATopic, ACopy);
        InvokeTopicHandlers(ATopic, ACopy);
      finally
        FreeMessage(ACopy);
      end;
    end);
end;

function TQMQTTMessageClient.DNSLookupV4(

  const AHost: QStringW): Cardinal;
var
  Utf8Host: QStringA;
  AEntry: PHostEnt;
  function TryAsAddr(

    var AResult: Cardinal): Boolean;
  var
    p: PQCharW;
    I, V: Integer;
    B: array [0 .. 3] of Byte absolute AResult;
  begin
    p := PQCharW(AHost);
    V := 0;
    I := 0;
    while p^ <> #0 do
    begin
      if (p^ >= '0') and (p^ <= '9') then
        V := V * 10 + Ord(p^) - Ord('0')
      else if p^ = '.' then
      begin
        if V > 255 then
        begin
          Result := false;
          Exit;
        end;
        B[I] := Byte(V);
        Inc(I);
        V := 0;
      end
      else
      begin
        Result := false;
        Exit;
      end;
      Inc(p);
    end;
    Result := (p^ = #0) and (I = 3) and (V < 256);
    if Result then
      B[I] := V;
  end;

begin
  if not TryAsAddr(Result) then
  begin
    Result := 0;
    Utf8Host := qstring.Utf8Encode(AHost);
    AEntry := gethostbyname({$IFDEF UNICODE}MarshaledAString{$ELSE}PAnsiChar{$ENDIF}(PQCharA(Utf8Host)));
    if Assigned(AEntry) then
    begin
      if AEntry.h_addrtype = AF_INET then
      begin
        if AEntry.h_addr_list^ <> nil then
          Result := PCardinal(AEntry.h_addr_list^)^;
      end;
    end;
  end;
end;

procedure TQMQTTMessageClient.DoAfterConnected;
begin
  Queue(
    procedure
    var
      ALevel, ALastLevel: TQMQTTQoSLevel;
      ATopics: array of String;
      ATopic: String;
      I, C: Integer;
    begin
      FConnected := true;
      FReconnectTimes := 0; // �����������
      FReconnectTime := 0;
      FStates := FStates - [qcsConnecting];
      if Assigned(FAfterConnected) then
        FAfterConnected(Self);
      if FSubscribes.Count > 0 then
      begin
        SetLength(ATopics, FSubscribes.Count);
        ALevel := qlMax1;
        ALastLevel := ALevel;
        C := 0;
        for I := 0 to FSubscribes.Count - 1 do
        begin
          ATopic := FSubscribes[I];
          ALevel := TQMQTTQoSLevel(StrToIntDef(NameOfW(ATopic, '|'), 0));
          if ALevel <> ALastLevel then
          begin
            Subscribe(Copy(ATopics, 0, C), ALastLevel);
            C := 0;
            ALastLevel := ALevel;
          end;
          ATopics[C] := ValueOfW(ATopic, '|');
          Inc(C);
        end;
        if C > 0 then
          Subscribe(Copy(ATopics, 0, C), ALastLevel);
      end
    end);
end;

procedure TQMQTTMessageClient.DoAfterSent(

  const AReq: PQMQTTMessage);
begin
  if Assigned(AReq.FAfterSent) or Assigned(FAfterSent) then
  begin
    Queue(
      procedure
      begin
        if Assigned(AReq.FAfterSent) then
          AReq.FAfterSent(AReq);
        if Assigned(FAfterSent) then
          FAfterSent(AReq);
      end);
  end;
end;

procedure TQMQTTMessageClient.DoAfterDisconnected;
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if Assigned(FAfterDisconnected) then
        FAfterDisconnected(Self);
    end);
end;

procedure TQMQTTMessageClient.DoAfterSubcribed(AResult: PQMQTTSubscribeResults);
begin
  if Assigned(FAfterSubscribed) then
  begin
    Queue(
      procedure
      begin
        try
          if Assigned(FAfterSubscribed) then
            FAfterSubscribed(Self, AResult^);
        finally
          Dispose(AResult);
        end;
      end);
  end
  else
    Dispose(AResult);
end;

procedure TQMQTTMessageClient.DoAfterUnsubscribed(ASource: PQMQTTMessage);
begin
  if Assigned(FAfterUnsubscribed) and Assigned(ASource) then
  begin
    Queue(
      procedure
      begin
        try
          if Assigned(FAfterUnsubscribed) then
          begin
            ASource.Position := ASource.VarHeaderOffset + 2;
            while ASource.Current < ASource.Eof do
              FAfterUnsubscribed(Self, ASource.NextString);
          end;
        finally
          FreeMessage(ASource);
        end;
      end);
  end
  else
    FreeMessage(ASource);
end;

procedure TQMQTTMessageClient.DoBeforeConnect;
begin
  if Assigned(FBeforeConnect) then
  begin
    Queue(
      procedure
      begin
        FStates := FStates + [qcsConnecting];
        if Assigned(FBeforeConnect) then
          FBeforeConnect(Self);
      end)
  end;
end;

procedure TQMQTTMessageClient.DoBeforePublish(ATopic: String; AMsg: PQMQTTMessage);
begin
  if Assigned(FBeforePublish) then
  begin
    Queue(
      procedure
      begin
        if Assigned(FBeforePublish) then
          FBeforePublish(Self, ATopic, AMsg);
      end);
  end;
end;

procedure TQMQTTMessageClient.DoBeforeSend(

  const AReq: PQMQTTMessage);
begin
  if Assigned(FBeforeSend) then
  begin
  end;
end;

procedure TQMQTTMessageClient.DoCleanup;
begin
{$IFDEF EnableSSLMqtt}
  if Assigned(FSSL) then
    FreeAndNil(FSSL);
{$ENDIF}
end;

procedure TQMQTTMessageClient.DoCloseSocket;
begin
  if FSocket <> 0 then
  begin
    shutdown(FSocket, SD_BOTH);
    closesocket(FSocket);
    FSocket := 0;
    FPingStarted := 0;
    DoAfterDisconnected;
{$IFDEF  EnableSSLMqtt}
    if Assigned(FSSL) then
      FreeAndNil(FSSL);
{$ENDIF}
  end;
end;

procedure TQMQTTMessageClient.DoConnect;
var
  AReq: PQMQTTMessage;
  AUserName, APassword, AClientId, AWillTopic: QStringA;
  APayloadSize: Integer;
  AHeader: PMQTTConnectHeader;

const
  Protocol: array [0 .. 5] of Byte = (0, 4, Ord('M'), Ord('Q'), Ord('T'), Ord('T'));
begin
  FConnected := false;
  AReq := TQMQTTMessage.Create(Self);
  APayloadSize := SizeOf(TQMQTTConnectHeader);
  if Length(FUserName) > 0 then
  begin
    AUserName := qstring.Utf8Encode(FUserName);
    Inc(APayloadSize, 2 + AUserName.Length);
  end;
  if Length(FPassword) > 0 then
  begin
    APassword := qstring.Utf8Encode(FPassword);
    Inc(APayloadSize, 2 + APassword.Length);
  end;
  ValidClientId;
  AClientId := qstring.Utf8Encode(FClientId);
  Inc(APayloadSize, 2 + AClientId.Length);
  if (Length(FWillTopic) > 0) and (Length(FWillMessage) > 0) then
  begin
    AWillTopic := qstring.Utf8Encode(FWillTopic);
    Inc(APayloadSize, 4 + AWillTopic.Length + Length(FWillMessage));
  end;
  if (ProtocolVersion = pv5_0) then
  begin
    if Assigned(FConnectProps) then
      Inc(APayloadSize, FConnectProps.PayloadSize)
    else
      Inc(APayloadSize, 1);
  end;
  AReq.PayloadSize := APayloadSize;
  AReq.ControlType := ctConnect;
  AReq.IsRetain := IsRetain;
  AReq.QosLevel := QosLevel;
  AHeader := PMQTTConnectHeader(AReq.Current);
  Move(Protocol, AHeader^.Protocol, 6);
  with AHeader^ do
  begin
    Level := Ord(ProtocolVersion);
    // MQTT 3.1.1
    Flags := 0;
    if Length(FUserName) > 0 then
      Flags := Flags or $80;
    if Length(FPassword) > 0 then
      Flags := Flags or $40;
    if IsRetain then
      Flags := Flags or $20;
    Flags := Flags or (Ord(QosLevel) shl 3);
    if Length(FWillTopic) > 0 then
      Flags := Flags or $04;
    if CleanLastSession then
      Flags := Flags or $02;
    Interval := ExchangeByteOrder(FPeekInterval);
  end;
  AReq.MoveBy(SizeOf(TQMQTTConnectHeader));
  if (ProtocolVersion = pv5_0) then
  begin
    if Assigned(FConnectProps) then
      FConnectProps.WriteProps(AReq)
    else
      AReq.Cat(Byte(0));
  end;
  AReq.Cat(AClientId);
  if (Length(FWillTopic) > 0) and (Length(FWillMessage) > 0) then
    AReq.Cat(AWillTopic).Cat(Word(Length(FWillMessage))).Cat(FWillMessage);
  if Length(FUserName) > 0 then
    AReq.Cat(AUserName);
  if Length(FPassword) > 0 then
    AReq.Cat(APassword);
  AReq.FAfterSent := DoFreeAfterSent;
  if Assigned(FSendThread) then
    TSocketSendThread(FSendThread).Post(AReq);
end;

procedure TQMQTTMessageClient.DoConnectFailed;
begin
  TThread.Queue(nil,
    procedure
    begin
      FStates := FStates - [qcsConnecting];
    end);
end;

procedure TQMQTTMessageClient.DoDispatch(var AReq: TQMQTTMessage);

  procedure DispatchConnectAck;
  var
    AErrorCode: Byte;
  begin
    Assert(AReq.PayloadSize >= 2); // RemainSize=2
    if ProtocolVersion = pv5_0 then
    begin
      AReq.MoveToVarHeader;
      AReq.MoveBy(1);
      // ������־λ��ֻ��һ���Ự�Ƿ����Ѿ����ڵı�ǣ����Ե�(0x01)
      AErrorCode := AReq.NextByte;
      if AErrorCode = 0 then
      begin
        DispatchProps(@AReq);
        DoAfterConnected;
      end
      else
      begin
        DoConnectFailed;
        DoError(MQERR_CONNECT + AErrorCode);
      end
    end
    else
    begin
      // �������
      case AReq[3] of
        0: //
          DoAfterConnected
      else
        begin
          DoConnectFailed;
          DoError(MQERR_CONNECT + AReq[3]);
          Stop;
        end;
      end;
    end;
  end;

  procedure DispatchSubscribeAck;
  var
    APackageId: Word;
    AAckPayload: Cardinal;
    ASource: PQMQTTMessage;
    AResults: PQMQTTSubscribeResults;
    AIdx: Integer;
    Ack: Byte;
  begin
    // �����̶���ͷ
    AReq.Position := 1;
    // �غɴ�С
    AAckPayload := AReq.NextDWord(true);
    // ��ϢID
    APackageId := AReq.NextWord(false);
    // ����(5.0+)
    DispatchProps(@AReq);
    ASource := PopWaitAck(APackageId);
    if Assigned(ASource) then
    begin
      New(AResults);
      try
        ASource.Position := ASource.VarHeaderOffset + 2;
        SetLength(AResults^, AAckPayload - 2); // ȥ��PackageId��ʣ�µ�ÿ���ֽڴ���һ�����
        AIdx := 0;
        while ASource.Current < ASource.Eof do
        begin
          with AResults^[AIdx] do
          begin
            Topic := ASource.NextString;
            Ack := AReq.NextByte;
            if (Ack and $80) <> 0 then
            begin
              DoError(MQERR_SUBSCRIBE_FAILED);
              ErrorCode := Ack;
              Qos := TQMQTTQoSLevel(ASource.NextByte);
            end
            else
            begin
              Qos := TQMQTTQoSLevel(Ack);
              ErrorCode := 0;
              ASource.NextByte;
            end;
          end;
          Inc(AIdx);
        end;
        DoAfterSubcribed(AResults);
        AResults := nil;
      finally
        FreeMessage(ASource);
        if Assigned(AResults) then
          Dispose(AResults);
      end;
    end;
  end;

  procedure DispatchPublish;
  var
    Ack: PQMQTTMessage;
    APackageId, ATopicLen: Word;
    AQoSLevel: TQMQTTQoSLevel;
  begin
    DispatchTopic(@AReq);
    AReq.Position := AReq.VarHeaderOffset;
    ATopicLen := AReq.NextWord(false);
    AReq.MoveBy(ATopicLen);
    AQoSLevel := AReq.QosLevel;
    if AQoSLevel > qlMax1 then
    begin
      APackageId := AReq.NextWord(false);
      Ack := TQMQTTMessage.Create(Self);
      Ack.PayloadSize := 2;
      if AQoSLevel = qlAtLeast1 then
        Ack.ControlType := TQMQTTControlType.ctPublishAck
      else
        Ack.ControlType := TQMQTTControlType.ctPublishRecv;
      Ack.Cat(APackageId);
      Ack.FAfterSent := DoFreeAfterSent;
      TSocketSendThread(FSendThread).Post(Ack);
    end;
  end;

  procedure DoPublishAck;
  var
    APackageId: Word;
  begin
    AReq.Position := AReq.VarHeaderOffset;
    APackageId := AReq.NextWord(false);
    Queue(
      procedure
      begin
        DoTopicPublished(PopWaitAck(APackageId));
      end);
  end;

  procedure DoPublishRelease;
  var
    APackageId: Word;
    Ack: PQMQTTMessage;
  begin
    AReq.Position := AReq.VarHeaderOffset;
    APackageId := AReq.NextWord(false);
    Queue(
      procedure
      var
        ASource: PQMQTTMessage;
      begin
        ASource := PopWaitAck(APackageId);
        if Assigned(ASource) then
          FreeMessage(ASource);
      end);
    Ack := TQMQTTMessage.Create(Self);
    Ack.PayloadSize := 2;
    Ack.ControlType := TQMQTTControlType.ctPublishDone;
    Ack.Cat(APackageId);
    Ack.FAfterSent := DoFreeAfterSent;
    TSocketSendThread(FSendThread).Post(Ack);
  end;

  procedure DoPublishRecv;
  var
    Ack: PQMQTTMessage;
    APackageId: Word;
  begin
    Ack := TQMQTTMessage.Create(Self);
    AReq.Position := AReq.VarHeaderOffset;
    APackageId := AReq.NextWord(false);
    Ack.PayloadSize := 2;
    Ack.IsRetain := true;
    Ack.ControlType := TQMQTTControlType.ctPublishRelease;
    Ack.Position := AReq.VarHeaderOffset;
    Ack.Cat(APackageId);
    Ack.FAfterSent := DoFreeAfterSent;
    TSocketSendThread(FSendThread).Post(Ack);
  end;

  procedure DoUnsubscribeAck;
  var
    APackageId: Word;
  begin
    AReq.Position := AReq.VarHeaderOffset;
    APackageId := AReq.NextWord(false);
    Queue(
      procedure
      begin
        DoAfterUnsubscribed(PopWaitAck(APackageId));
      end);
  end;

  procedure DoPingAck;
  begin
    Queue(
      procedure
      begin
{$IFDEF LogMqttContent}
        PostLog(llDebug, 'Ping ������������ʱ %d ms', [GetTickCount - FPingStarted], 'QMQTT');
{$ENDIF}
        FPingStarted := 0;
      end);
  end;

begin
{$IFDEF LogMqttContent}
  if LogPackageContent then
    PostLog(llDebug, '[����]�յ����� %d��TopicId=%d,�غɴ�С:%d,�ܴ�С:%d ����:'#13#10'%s', [Ord(AReq.ControlType), Integer(AReq.TopicId),
      Integer(AReq.PayloadSize), Integer(AReq.Size), AReq.ContentAsHexText], 'QMQTT')
  else
    PostLog(llDebug, '[����]�յ����� %d��TopicId=%d,�غɴ�С:%d,�ܴ�С:%d', [Ord(AReq.ControlType), Integer(AReq.TopicId),
      Integer(AReq.PayloadSize), Integer(AReq.Size)], 'QMQTT');
{$ENDIF}
  AReq.States := AReq.States + [msDispatching];
  case AReq.ControlType of
    ctConnectAck: // ���ӳɹ�
      DispatchConnectAck;
    ctPublish: // �յ���������������Ϣ
      DispatchPublish;
    ctPublishAck: // �յ���������������˵�ȷ��
      DoPublishAck;
    ctPublishRecv:
      DoPublishRecv;
    ctPublishRelease:
      DoPublishRelease;
    ctPublishDone:
      DoPublishAck;
    ctSubscribeAck:
      DispatchSubscribeAck;
    ctUnsubscribeAck:
      DoUnsubscribeAck;
    ctPingResp:
      DoPingAck;
  end;
  AReq.States := AReq.States + [msDispatched];
end;

procedure TQMQTTMessageClient.DoError(AErrorCode: Integer);
const
  KnownErrorMessages: array [0 .. 6] of String = ('�����ɹ����', 'Э��汾�Ų���֧��', '�ͻ���ID������', '���񲻿���', '�û������������', '�ͻ���δ����Ȩ����',
    '����ָ��������ʧ��');
var
  AMsg: String;
begin
  if Assigned(FOnError) then
  begin
    if AErrorCode < Length(KnownErrorMessages) then
      AMsg := KnownErrorMessages[AErrorCode]
    else
      AMsg := 'δ֪�Ĵ�����룺' + IntToStr(AErrorCode);
    Queue(
      procedure
      begin
        FOnError(Self, AErrorCode, AMsg);
      end);
  end;
end;

procedure TQMQTTMessageClient.DoFreeAfterSent(

  const AMessage: PQMQTTMessage);
begin
  FreeMessage(AMessage);
end;

procedure TQMQTTMessageClient.DoPing;
var
  AReq: PQMQTTMessage;
begin
  if (FPingStarted = 0) and Assigned(FSendThread) then
  begin
    FPingStarted := GetTickCount;
    AReq := TQMQTTMessage.Create(Self);
    AReq.PayloadSize := 0;
    AReq.ControlType := TQMQTTControlType.ctPing;
    AReq.FAfterSent := DoFreeAfterSent;
    TSocketSendThread(FSendThread).Post(AReq);
  end;
end;

procedure TQMQTTMessageClient.FreeMessage(AMsg: PQMQTTMessage);
var
  APkgId: Word;
begin
  if Assigned(AMsg) then
  begin
    Lock;
    try
      APkgId := AMsg.TopicId;
      if APkgId <> 0 then
      begin
        if Assigned(FWaitAcks[APkgId]) and (FWaitAcks[APkgId] = AMsg) then
          DebugBreak;
      end;
    finally
      Unlock;
    end;
    Dispose(AMsg);
  end;
end;

function TQMQTTMessageClient.GetClientId: String;
begin
  ValidClientId;
  Result := FClientId;
end;

function TQMQTTMessageClient.GetConnectProps: TQMQTT5Props;
begin
  if not Assigned(FConnectProps) then
    FConnectProps := TQMQTT5Props.Create;
  Result := FConnectProps;
end;

function TQMQTTMessageClient.GetIsRunning: Boolean;
begin
  Result := Assigned(FRecvThread) and Assigned(FSendThread) and (FSocket <> 0);
end;
{$IFDEF EnableSSLMqtt}

function TQMQTTMessageClient.GetSSLManager: TQSSLManager;
begin
  Result := TQSSLManager.Current;
end;
{$ENDIF}

procedure TQMQTTMessageClient.Lock;
begin
  TMonitor.Enter(Self);
end;

procedure TQMQTTMessageClient.Publish(

  const ATopic, AContent: String; AQoSLevel: TQMQTTQoSLevel);
var
  AUtf8Content: QStringA;
begin
  if not IsRunning then
    Exit;
  AUtf8Content := qstring.Utf8Encode(AContent);
  Publish(ATopic, AUtf8Content.Data^, AUtf8Content.Length, AQoSLevel);
end;

procedure TQMQTTMessageClient.Publish(

  const ATopic: String; AContent: TBytes; AQoSLevel: TQMQTTQoSLevel);
begin
  Publish(ATopic, AContent[0], Length(AContent), AQoSLevel)
end;

function TQMQTTMessageClient.PopWaitAck(APackageId: Word): PQMQTTMessage;
begin
  Lock;
  try
    if APackageId < Length(FWaitAcks) then
    begin
      Result := FWaitAcks[APackageId];
      FWaitAcks[APackageId] := nil;
    end
    else
      Result := nil;
  finally
    Unlock;
  end;
end;

procedure TQMQTTMessageClient.Publish(

  const ATopic: String;

const AContent; ALen: Cardinal; AQoSLevel: TQMQTTQoSLevel);
var
  AReq: PQMQTTMessage;
  AUtf8Topic: QStringA;
  APackageId: Word;
  ANeedAck: Boolean;
  APayloadSize: Cardinal;
begin
  if not IsRunning then
    Exit;
  Assert(Length(ATopic) > 0);
  AUtf8Topic := qstring.Utf8Encode(ATopic);
  // �ж��ܳ��Ȳ��ܳ�������
  APayloadSize := SizeOf(Word) + Cardinal(AUtf8Topic.Length) + ALen;
  ANeedAck := AQoSLevel <> TQMQTTQoSLevel.qlMax1;
  if ANeedAck then
    Inc(APayloadSize, 2);
  AReq := TQMQTTMessage.Create(Self);
  AReq.PayloadSize := APayloadSize;
  AReq.ControlType := TQMQTTControlType.ctPublish;
  AReq.QosLevel := AQoSLevel;
  AReq.IsRetain := IsRetain;
  // ������
  AReq.Cat(AUtf8Topic);
  // ��־��
  if ANeedAck then
  begin
    APackageId := AcquirePackageId(AReq, ANeedAck);
    AReq.Cat(APackageId);
  end;
  AReq.Cat(@AContent, ALen);
  DoBeforePublish(ATopic, AReq);
  if AQoSLevel = TQMQTTQoSLevel.qlMax1 then
    AReq.FAfterSent := DoTopicPublished;
  TSocketSendThread(FSendThread).Post(AReq);
end;

procedure TQMQTTMessageClient.Queue(ACallback: TThreadProcedure);
begin
  TThread.Queue(nil, ACallback);
end;

procedure TQMQTTMessageClient.ReconnectNeeded;
begin
  DoCloseSocket;
  FStates := FStates + [qcsReconnecting];
  if FReconnectTimes = 0 then
    FReconnectTime := TThread.GetTickCount;
  if FReconnectTimes < 5 then // 5�ξ�������,����5�Σ���Ҫȥ����ʱ����ʱ����
  begin
    Inc(FReconnectTimes);
    if not(qcsStop in FStates) then
      RecreateSocket;
  end;
end;

procedure TQMQTTMessageClient.RecreateSocket;
var
  Addr: TSockAddrIn;
  tm: TTimeVal;
  mode: Integer;
  fdWrite, fdError: TFdSet;
begin
  DoCloseSocket;
  DoBeforeConnect;
  FSocket := Socket(PF_INET, SOCK_STREAM, 0);
  if FSocket = THandle(INVALID_SOCKET) then
    RaiseLastOSError;
  try
    // ���ӵ�Զ�̵�ַ
    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(FServerPort);
    Addr.sin_addr.S_addr := DNSLookupV4(FServerHost);
    if Addr.sin_addr.S_addr = 0 then
      RaiseLastOSError;
    tm.tv_sec := FConnectionTimeout div 1000;
    tm.tv_usec := (FConnectionTimeout mod 1000) * 1000;
    mode := 1;
    if ioctlsocket(FSocket, FIONBIO, mode) <> NO_ERROR then
      RaiseLastOSError;
    CONNECT(FSocket, TSockAddr(Addr), SizeOf(Addr));
    FD_ZERO(fdWrite);
    FD_ZERO(fdError);
    FD_SET(FSocket, fdWrite);
    FD_SET(FSocket, fdError);
    select(0, nil, @fdWrite, @fdError, @tm);
    if not FD_ISSET(FSocket, fdWrite) then
      RaiseLastOSError;
{$IFDEF EnableSSLMqtt}
    if UseSSL and (not Assigned(FSSL)) then
    begin
      if TQSSLManager.Current.Initialized then
      begin
        // SSL ʹ������ģʽ,�첽ģʽ�����е�С����:)
        mode := 0;
        if ioctlsocket(FSocket, FIONBIO, mode) <> NO_ERROR then
          RaiseLastOSError;
        FSSL := TQSSLManager.Current.NewItem;
        FSSL.Bind(FSocket);
        FSSL.Modes := [TQSSLMode.AutoReply];
        if not FSSL.CONNECT then
        begin
          Abort;
        end;
        // raise Exception.Create(FSSL.LastErrorMsg);
        // �������ٵ�����ȥ:)
        mode := 1;
        if ioctlsocket(FSocket, FIONBIO, mode) <> NO_ERROR then
          RaiseLastOSError;
      end
      else
      begin
        Stop;
        raise Exception.Create(SInitSSLFailed);
      end;
    end;
{$ENDIF}
    DoConnect;
    FLastConnectTime := GetTickCount;
  except
    on E: Exception do
    begin
      mode := GetLastError;
      if Assigned(FOnError) then
        FOnError(Self, mode, E.Message);
      FStates := FStates - [qcsConnecting];
      DoCloseSocket;
      FReconnectTime := GetTickCount;
      if not(qcsReconnecting in FStates) then
      begin
        if qcsRunning in FStates then
          FStates := FStates + [qcsReconnecting];
        raise;
      end;
    end;
  end;
end;

procedure TQMQTTMessageClient.RegisterDispatch(const ATopic: String; AHandler: TQMQTTTopicDispatchEventG;
AType: TTopicMatchType);
var
  AMethod: TMethod;
  ATemp: TQMQTTTopicDispatchEvent absolute AMethod;
begin
  AMethod.Data := nil;
  AMethod.Code := @AHandler;
  RegisterDispatch(ATopic, ATemp, AType);
end;

procedure TQMQTTMessageClient.RegisterDispatch(const ATopic: String; AHandler: TQMQTTTopicDispatchEventA;
AType: TTopicMatchType);
var
  AMethod: TMethod;
  ATemp: TQMQTTTopicDispatchEvent absolute AMethod;
begin
  AMethod.Data := nil;
  TQMQTTTopicDispatchEventA(AMethod.Code) := AHandler;
  RegisterDispatch(ATopic, ATemp, AType);
end;

procedure TQMQTTMessageClient.RegisterDispatch(const ATopic: String; AHandler: TQMQTTTopicDispatchEvent;
AType: TTopicMatchType);
var
  AItem, AFirst: TTopicHandler;
  AIdx: Integer;
  ARealTopic: String;
begin
  if AType = TTopicMatchType.mtRegex then
    ARealTopic := RegexTopic
  else if AType = TTopicMatchType.mtPattern then
    ARealTopic := PatternTopic
  else
    ARealTopic := ATopic;
  if FTopicHandlers.Find(ARealTopic, AIdx) then
    AFirst := TTopicHandler(FTopicHandlers.Objects[AIdx])
  else
    AFirst := nil;
  AItem := AFirst;
  // ���������Ӧ�Ƿ�ע������Ա����ظ�ע��
  while Assigned(AItem) do
  begin
    if MethodEqual(TMethod(AItem.FOnDispatch), TMethod(AHandler)) then
      Exit;
    AItem := AItem.FNext;
  end;
  // û�ҵ�����һ���µ���ӽ�ȥ
  AItem := TTopicHandler.Create(ATopic, AHandler, AType);
  AItem.FNext := AFirst;
  if Assigned(AFirst) then
    FTopicHandlers.Objects[AIdx]:=AItem
  else
    FTopicHandlers.AddObject(ARealTopic, AItem);
end;

procedure TQMQTTMessageClient.DoRecv;
var
  AReq: PQMQTTMessage;
  AReaded, ATotal, ATick, ALastLargeIoTick: Cardinal;
  ARecv: Integer;
  tm: TTimeVal;
  fdRead, fdError: TFdSet;
  rc: Integer;
  AErrorCode: Integer;
  ALastHandle: THandle;
const
  InvalidSize = Cardinal(-1);
  MinBufferSize = 4096;
  function ReadSize: Boolean;
  begin
    Result := AReq.ReloadSize(AReaded);
    if Result then
      ATotal := AReq.Size
    else
      ATotal := InvalidSize;
  end;

begin
  AReq := TQMQTTMessage.Create(Self);
  try
    FReconnectTimes := 0;
    ALastLargeIoTick := 0;
    ALastHandle := FSocket;
    if FSocket = 0 then
      TThread.Queue(nil, RecreateSocket);
    repeat
      while (FSocket = 0) do
      begin
        if TSocketRecvThread(TThread.Current).Terminated then
          Exit;
        Sleep(10);
      end;
      AReq.States := [msRecving];
      AReq.Capacity := MinBufferSize;
      AReaded := 0;
      ATotal := Cardinal(-1);
      tm.tv_sec := 1;
      tm.tv_usec := 0;
      AErrorCode := 0;
      repeat
        FD_ZERO(fdRead);
        FD_ZERO(fdError);
        FD_SET(FSocket, fdRead);
        FD_SET(FSocket, fdError);
        try
          rc := select(0, @fdRead, nil, @fdError, @tm);
          if (rc > 0) then
          begin
            if FD_ISSET(FSocket, fdRead) and (not FD_ISSET(FSocket, fdError)) then
            begin
{$IFDEF EnableSSLMqtt}
              if UseSSL then
              begin
                if Assigned(FSSL) then
                  ARecv := FSSL.Read(AReq.FData[AReaded], Cardinal(Length(AReq.FData)) - AReaded)
                else
                  Exit;
              end
              else
{$ENDIF}
                ARecv := Recv(FSocket, AReq.FData[AReaded], Cardinal(Length(AReq.FData)) - AReaded, 0);
              if TSocketRecvThread(TThread.Current).Terminated then
                Break;
              if ARecv = SOCKET_ERROR then
              begin
                if GetLastError = WSAEWOULDBLOCK then
                begin
                  Sleep(10);
                  continue;
                end
                else
                begin
                  AErrorCode := GetLastError;
                  Break;
                end;
              end
              else if ARecv = 0 then // û�н�һ��������ʱ���ó�CPU
              begin
                TThread.Queue(nil, DoPing);
                SleepEx(10, true);
                continue;
              end;
              Inc(AReaded, ARecv);
              FLastIoTick := GetTickCount;
              if AReaded > 4096 then
                ALastLargeIoTick := FLastIoTick;
              if ATotal = InvalidSize then
                ReadSize; // ���Խ������ֽ���
              if ATotal <= AReaded then
              begin
                if AReaded >= AReq.Size then
                begin
                  AReq.FRecvTime := FLastIoTick;
                  AReq.States := AReq.States + [msRecved];
                  repeat
                    DoDispatch(AReq^);
                    ATotal := AReq.Size;
                    if AReaded > AReq.Size then
                      Move(AReq.FData[ATotal], AReq.FData[0], AReaded - ATotal);
                    Dec(AReaded, ATotal);
                    if not ReadSize then
                      Break;
                  until AReaded < AReq.Size;
                end;
              end;
            end
            else
            begin
              AErrorCode := GetLastError;
              Break;
            end;
          end
          else if rc < 0 then
          begin
            AErrorCode := GetLastError;
            Break;
          end
          else if rc = 0 then // ��ʱ������Ƿ���ҪPing
          begin
            ATick := GetTickCount;
            // ����5���ȡ������乻��������ݣ�����С�ڴ�ռ��
            if (AReq.Capacity > MinBufferSize) and (AReaded < MinBufferSize) and (ATick - ALastLargeIoTick > 5000) then
            begin
              AReq.PayloadSize := 0;
              AReq.Capacity := MinBufferSize;
            end;
          end;
        except

        end;
      until TSocketRecvThread(TThread.Current).Terminated;
      if (AErrorCode <> 0) and (not TSocketThread(TThread.Current).Terminated) then
      begin
        DebugOut(SysErrorMessage(AErrorCode));
        ALastHandle := FSocket;
        TThread.Synchronize(nil, ReconnectNeeded);
      end;
    until TSocketThread(TThread.Current).Terminated;
  finally
    DoCloseSocket;
    FreeMessage(AReq);
    FRecvThread := nil;
  end;
end;

function TQMQTTMessageClient.DoSend(AReq: PQMQTTMessage): Boolean;
var
  ASent: Integer;
  p: PByte;
  ASize: Integer;
begin
{$IFDEF LogMqttContent}
  if LogPackageContent then
    PostLog(llDebug, '�������� %d(%x),ID=%d,�غɴ�С:%d,�ܴ�С:%d,����:'#13#10'%s', [Ord(AReq.ControlType), IntPtr(AReq),
      Integer(AReq.TopicId), Integer(AReq.PayloadSize), Integer(AReq.Size), AReq.ContentAsHexText], 'QMQTT')
  else
    PostLog(llDebug, '�������� %d(%x),ID=%d,�غɴ�С:%d,�ܴ�С:%d', [Ord(AReq.ControlType), IntPtr(AReq), Integer(AReq.TopicId),
      Integer(AReq.PayloadSize), Integer(AReq.Size)], 'QMQTT');
{$ENDIF}
  Result := false;
  DoBeforeSend(AReq);
  try
    p := AReq.Bof;
    ASize := AReq.Size;
    while (ASize > 0) and (not TSocketThread(TThread.Current).Terminated) do
    begin
{$IFDEF EnableSSLMqtt}
      if UseSSL then
      begin
        if not Assigned(FSSL) then
          Exit;
        ASent := FSSL.Write(p^, ASize);
        if ASent > 0 then
        begin
          Inc(p, ASent);
          Dec(ASize, ASent);
        end
        else
        begin
          // ��ʱ���˽�SSL��飬����
        end;
      end
      else
{$ENDIF}
      begin
        ASent := Send(AReq.Client.FSocket, p^, ASize, 0);
        if ASent <> SOCKET_ERROR then
        begin
          Inc(p, ASent);
          Dec(ASize, ASent);
        end
        else if ASent = WSAEWOULDBLOCK then
        begin
          Sleep(10);
          continue
        end
        else
          Break;
      end;
    end;
    if ASize = 0 then
    begin
      AReq.States := AReq.States + [msSent] - [msSending];
      AReq.FSentTime := GetTickCount;
      Inc(AReq.FSentTimes);
      AReq.Client.FLastIoTick := AReq.FSentTime;
      Result := true;
      DoAfterSent(AReq);
    end;
  except
    on E: Exception do
    begin
      DebugOut('��������ʱ�����쳣:' + E.Message);
    end
  end;
end;

procedure TQMQTTMessageClient.DoTimer(ASender: TObject);
var
  ATick: Cardinal;
begin
  ATick := GetTickCount;
  if qcsConnecting in FStates then
    Exit;
  if FSocket = 0 then
  begin
    if ((ATick - FReconnectTime) > (FReconnectInterval * 1000)) and (qcsRunning in FStates) then
      RecreateSocket;
  end
  else if ((ATick - FLastIoTick) >= (FPeekInterval * 1000)) then
    DoPing
  else if (FPingStarted > 0) and ((ATick - FPingStarted) > 1000) then // Ping ������1���ڷ��أ����������ֱ������
    ReconnectNeeded;
end;

procedure TQMQTTMessageClient.DoTopicPublished(

  const AMessage: PQMQTTMessage);
var
  ATopic: String;
begin
  if Assigned(FAfterPublished) and Assigned(AMessage) then
  begin
    Queue(
      procedure
      begin
        try
          Inc(FSentTopics);
          if Assigned(FAfterPublished) then
          begin
            AMessage.Position := AMessage.VarHeaderOffset;
            ATopic := AMessage.NextString;
            FAfterPublished(Self, ATopic, AMessage);
          end;
        finally
          FreeMessage(AMessage);
        end;
      end);
  end
  else
    FreeMessage(AMessage);
end;

procedure TQMQTTMessageClient.SetWillMessage(const AValue: TBytes);
begin
  FWillMessage := Copy(AValue, 0, Length(AValue));
end;

procedure TQMQTTMessageClient.Start;
begin
  FStates := [qcsConnecting, qcsRunning];
  ClearWaitAcks;
  SetLength(FWaitAcks, 65536);
  if not Assigned(FRecvThread) then
    FRecvThread := TSocketRecvThread.Create(Self);
  if not Assigned(FSendThread) then
    FSendThread := TSocketSendThread.Create(Self);
  FTimer.Enabled := true;
end;

procedure TQMQTTMessageClient.Stop;
begin
  FStates := FStates + [qcsStop] - [qcsRunning];
  FReconnectTimes := 0;
  FReconnectTime := 0;
  FTimer.Enabled := false;
  Disconnect;
  DoCloseSocket;
  if Assigned(FRecvThread) then
  begin
    FRecvThread.Terminate;
    FRecvThread := nil;
  end;
  if Assigned(FSendThread) then
  begin
    FSendThread.Terminate;
    TSocketSendThread(FSendThread).FNotifyEvent.SetEvent;
    FSendThread := nil;
  end;
  Sleep(10);
  ClearWaitAcks;
end;

procedure TQMQTTMessageClient.Subscribe(const ATopics: array of String; const AQoS: TQMQTTQoSLevel; AProps: TQMQTT5Props);
var
  AReq: PQMQTTMessage;
  APayloadSize: Integer;
  APayloads: TArray<QStringA>;
  I, C: Integer;
  APackageId: Word;
begin
  for I := Low(ATopics) to High(ATopics) do
  begin
    if Assigned(AProps) then
      FSubscribes.AddObject(IntToStr(Ord(AQoS)) + '|' + ATopics[I], AProps.Copy)
    else
      FSubscribes.AddObject(IntToStr(Ord(AQoS)) + '|' + ATopics[I], nil);
  end;
  if not IsRunning then
    Exit;
  SetLength(APayloads, Length(ATopics));
  APayloadSize := Length(ATopics) * 3 + 2;
  C := 0;
  for I := 0 to High(ATopics) do
  begin
    APayloads[I] := qstring.Utf8Encode(ATopics[I]);
    if APayloads[I].Length > 0 then
    begin
      Inc(APayloadSize, APayloads[I].Length);
      Inc(C);
    end;
  end;
  if C > 0 then
  begin
    if (ProtocolVersion = pv5_0) then
    begin
      if Assigned(AProps) then
        Inc(APayloadSize, AProps.PayloadSize)
      else
        Inc(APayloadSize);
    end;
    AReq := TQMQTTMessage.Create(Self);
    AReq.PayloadSize := APayloadSize;
    AReq.ControlType := TQMQTTControlType.ctSubscribe;
    AReq.QosLevel := TQMQTTQoSLevel.qlAtLeast1;
    // ���ı�־��
    APackageId := AcquirePackageId(AReq, true);
    AReq.Cat(APackageId);
    if (ProtocolVersion = pv5_0) then
    begin
      if Assigned(AProps) then
        AProps.WriteProps(AReq)
      else
        AReq.Cat(Byte(0));
      // EncodeInt
    end;
    for I := 0 to High(APayloads) do
      AReq.Cat(APayloads[I]).Cat(Byte(Ord(AQoS)));
    TSocketSendThread(FSendThread).Post(AReq);
  end;
end;

procedure TQMQTTMessageClient.Unlock;
begin
  TMonitor.Exit(Self);
end;

procedure TQMQTTMessageClient.UnregisterDispatch(AHandler: TQMQTTTopicDispatchEvent);
var
  AItem, APrior, ANext: TTopicHandler;
  I: Integer;
begin
  I := 0;
  while I < FTopicHandlers.Count do
  begin
    AItem := TTopicHandler(FTopicHandlers.Objects[I]);
    APrior := nil;
    while Assigned(AItem) do
    begin
      if MethodEqual(TMethod(AItem.FOnDispatch), TMethod(AHandler)) then
      begin
        if Assigned(APrior) then
          APrior.FNext := AItem.FNext
        else
          FTopicHandlers.Objects[I] := AItem.FNext;
        ANext := AItem.FNext;
        FreeAndNil(AItem);
        AItem := ANext;
      end
      else
        AItem := AItem.FNext;
    end;
    if FTopicHandlers.Objects[I] = nil then
      FTopicHandlers.Delete(I)
    else
      Inc(I);
  end;
end;

procedure TQMQTTMessageClient.Unsubscribe(

  const ATopics: array of String);
var
  AReq: PQMQTTMessage;
  APayloadSize: Integer;
  AUtf8Topics: TArray<QStringA>;
  I, C: Integer;
  APackageId: Word;
begin
  if not IsRunning then
    Exit;
  if Length(ATopics) > 0 then
  begin
    SetLength(AUtf8Topics, Length(ATopics));
    C := 0;
    APayloadSize := 2;
    for I := 0 to High(ATopics) do
    begin
      if Length(ATopics[I]) > 0 then
      begin
        AUtf8Topics[C] := qstring.Utf8Encode(ATopics[I]);
        Inc(APayloadSize, AUtf8Topics[C].Length + 2);
        Inc(C);
      end;
    end;
    if C = 0 then
      // û��Ҫȡ���Ķ��ģ��˳�
      Exit;
    AReq := TQMQTTMessage.Create(Self);
    AReq.PayloadSize := APayloadSize;
    AReq.ControlType := TQMQTTControlType.ctUnsubscribe;
    APackageId := AcquirePackageId(AReq, true);
    AReq.Cat(APackageId);
    for I := 0 to C - 1 do
      AReq.Cat(AUtf8Topics[I]);
    if Assigned(BeforeUnsubscribe) then
    begin
      for I := 0 to High(ATopics) do
      begin
        if Length(ATopics[I]) > 0 then
          BeforeUnsubscribe(Self, ATopics[I], AReq);
      end;
    end;
    TSocketSendThread(FSendThread).Post(AReq);
  end;
end;

procedure TQMQTTMessageClient.ValidClientId;
var
  AId: TGuid;
begin
  if Length(FClientId) = 0 then
  begin
    CreateGUID(AId);
    FClientId := DeleteRightW(TNetEncoding.Base64.EncodeBytesToString(@AId, SizeOf(AId)), '=', false, 1);
  end;
end;

{ TQMQTTMessage }

function TQMQTTMessage.Cat(

  const V: Cardinal; AEncode: Boolean): PQMQTTMessage;
begin
  Result := @Self;
  if AEncode then
    EncodeInt(FCurrent, V)
  else
  begin
    PCardinal(FCurrent)^ := ExchangeByteOrder(V);
    Inc(FCurrent, SizeOf(V));
  end;
end;

function TQMQTTMessage.Cat(

  const V: Shortint): PQMQTTMessage;
begin
  Result := @Self;
  PShortint(FCurrent)^ := V;
  Inc(FCurrent, SizeOf(V));
end;

function TQMQTTMessage.Cat(

  const V: Smallint; AEncode: Boolean): PQMQTTMessage;
begin
  Result := @Self;
  if AEncode then
    EncodeInt(FCurrent, Word(V))
  else
  begin
    PSmallint(FCurrent)^ := ExchangeByteOrder(V);
    Inc(FCurrent, SizeOf(V));
  end;
end;

function TQMQTTMessage.Cat(

  const S: QStringW; AWriteZeroLen: Boolean): PQMQTTMessage;
var
  T: QStringA;
begin
  Result := @Self;
  if (Length(S) > 0) or AWriteZeroLen then
  begin
    T := qstring.Utf8Encode(S);
    Cat(Word(T.Length)).Cat(PQCharA(S), T.Length);
  end;
end;

function TQMQTTMessage.Cat(

  const V: Byte): PQMQTTMessage;
begin
  Result := @Self;
  FCurrent^ := V;
  Inc(FCurrent);
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.Cat(

  const V: Word; AEncode: Boolean): PQMQTTMessage;
begin
  Result := @Self;
  if AEncode then
    EncodeInt(FCurrent, V)
  else
  begin
    PWord(FCurrent)^ := ExchangeByteOrder(V);
    Inc(FCurrent, SizeOf(V));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.Cat(

  const V: Double; AEncode: Boolean): PQMQTTMessage;
var
  T: UInt64 absolute V;
begin
  Result := Cat(T, AEncode);
end;

function TQMQTTMessage.Copy: PQMQTTMessage;
begin
  Result := Create(Client);
  Result.PayloadSize := PayloadSize;
  Move(FData[0], Result.FData[0], FSize);
  Result.FStates := FStates;
  Result.FRecvTime := FRecvTime;
  Result.FSentTime := FSentTime;
  Result.FSentTimes := FSentTimes;
end;

class function TQMQTTMessage.Create(AClient: TQMQTTMessageClient): PQMQTTMessage;
begin
  New(Result);
  Result.FClient := AClient;
  Result.FAfterSent := nil;
  Result.FNext := nil;
  Result.FCurrent := nil;
  Result.FVarHeader := nil;
  Result.FStates := [];
  Result.FRecvTime := 0;
  Result.FSentTime := 0;
  Result.FSentTimes := 0;
  Result.FSize := 0;
  Result.FWaitEvent := nil;
end;

function TQMQTTMessage.Cat(

  const S: QStringA; AWriteZeroLen: Boolean): PQMQTTMessage;
var
  T: QStringA;
begin
  Result := @Self;
  if (S.Length > 0) or AWriteZeroLen then
  begin
    if S.IsUtf8 then
      Cat(Word(S.Length)).Cat(PQCharA(S), S.Length)
    else
    begin
      T := qstring.Utf8Encode(AnsiDecode(S));
      Cat(Word(T.Length)).Cat(PQCharA(T), T.Length)
    end;
    Assert(FCurrent <= Eof);
  end;
end;

function TQMQTTMessage.Cat(

  const ABytes: TBytes): PQMQTTMessage;
begin
  if Length(ABytes) > 0 then
    Result := Cat(@ABytes[0], Length(ABytes))
  else
    Result := @Self;
end;

function TQMQTTMessage.Cat(

  const V: Int64; AEncode: Boolean): PQMQTTMessage;
begin
  Result := Cat(UInt64(V), AEncode);
end;

function TQMQTTMessage.Cat(

  const V: UInt64; AEncode: Boolean): PQMQTTMessage;
begin
  Result := @Self;
  if AEncode then
    EncodeInt64(FCurrent, V)
  else
  begin
    PInt64(FCurrent)^ := ExchangeByteOrder(Int64(V));
    Inc(FCurrent, SizeOf(V));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.Cat(

  const ABuf: Pointer;

const ALen: Cardinal): PQMQTTMessage;
begin
  if ALen > 0 then
  begin
    Assert((FCurrent >= Bof) and (FCurrent + ALen <= Eof));
    Move(ABuf^, FCurrent^, ALen);
    Inc(FCurrent, ALen);
    Assert(FCurrent <= Eof);
  end;
  Result := @Self;
end;

function TQMQTTMessage.DecodeInt(

  var ABuf: PByte; AMaxCount: Integer;

var AResult: Cardinal): Boolean;
var
  C: Integer;
  AStart: PByte;
begin
  Result := false;
  C := 0;
  AResult := 0;
  AStart := ABuf;
  if AMaxCount < 0 then
  begin
    if (ABuf >= AStart) and (ABuf <= Eof) then
      AMaxCount := Integer(FSize) - (IntPtr(ABuf) - IntPtr(AStart))
    else
      AMaxCount := 4;
  end
  else if AMaxCount > 4 then
    AMaxCount := 4;
  while ABuf - AStart < AMaxCount do
  begin
    if (ABuf^ and $80) <> 0 then
    begin
      AResult := AResult + ((ABuf^ and $7F) shl (C * 7));
      Inc(ABuf);
    end
    else
    begin
      Inc(AResult, ABuf^ shl (C * 7));
      Inc(ABuf);
      Exit(true);
    end;
    Inc(C);
  end;
  // �ߵ����˵����ʽ��Ч
  AResult := 0;
end;

function TQMQTTMessage.DecodeInt64(var ABuf: PByte; AMaxCount: Integer;

var AResult: Int64): Boolean;
var
  C: Integer;
  AStart: PByte;
begin
  Result := false;
  C := 0;
  AStart := ABuf;
  AResult := 0;
  if AMaxCount < 0 then
  begin
    if (ABuf >= AStart) and (ABuf <= Eof) then
      AMaxCount := Integer(FSize) - (IntPtr(ABuf) - IntPtr(AStart))
    else
      AMaxCount := 8;
  end
  else if AMaxCount > 8 then
    AMaxCount := 8;
  while ABuf - AStart < AMaxCount do
  begin
    if (ABuf^ and $80) <> 0 then
    begin
      AResult := AResult + ((ABuf^ and $7F) shl (C * 7));
      Inc(ABuf);
    end
    else
    begin
      Inc(AResult, ABuf^ shl (C * 7));
      Inc(ABuf);
      Exit(true);
    end;
    Inc(C);
  end;
  // �ߵ����˵����ʽ��Ч
  AResult := 0;
end;

procedure TQMQTTMessage.EncodeInt(var ABuf: PByte; V: Cardinal);
begin
  repeat
    ABuf^ := V and $7F;
    V := V shr 7;
    if V > 0 then
      ABuf^ := ABuf^ or $80;
    Inc(ABuf);
  until V = 0;
end;

procedure TQMQTTMessage.EncodeInt64(var ABuf: PByte; V: UInt64);
begin
  repeat
    ABuf^ := V and $7F;
    V := V shr 7;
    if V > 0 then
      ABuf^ := ABuf^ or $80;
    Inc(ABuf);
  until V = 0;
end;

function TQMQTTMessage.Cat(const V: Single; AEncode: Boolean): PQMQTTMessage;
var
  T: Cardinal absolute V;
begin
  Result := @Self;
  if AEncode then
    EncodeInt(FCurrent, T)
  else
  begin
    PCardinal(FCurrent)^ := ExchangeByteOrder(T);
    Inc(FCurrent, SizeOf(V));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.Cat(const V: Integer; AEncode: Boolean): PQMQTTMessage;
var
  T: Cardinal absolute V;
begin
  Result := @Self;
  if AEncode then
    EncodeInt(FCurrent, T)
  else
  begin
    PInteger(FCurrent)^ := ExchangeByteOrder(V);
    Inc(FCurrent, SizeOf(V));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.GetBof: PByte;
begin
  Result := @FData[0];
end;

function TQMQTTMessage.GetByte(const AIndex: Integer): Byte;
begin
  Result := FData[AIndex];
end;

function TQMQTTMessage.GetCapacity: Cardinal;
begin
  Result := Length(FData);
end;

function TQMQTTMessage.GetControlType: TQMQTTControlType;
begin
  Assert(Length(FData) > 1);
  Result := TQMQTTControlType((FData[0] and $F0) shr 4);
end;

function TQMQTTMessage.GetEof: PByte;
begin
  Result := @FData[Length(FData)];
end;

function TQMQTTMessage.GetHeaderFlags(const Index: Integer): Boolean;
const
  AMasks: array [0 .. 1] of Byte = (1, 8);
begin
  Result := (FData[0] and AMasks[Index]) <> 0;
end;

function TQMQTTMessage.GetPayloadSize: Cardinal;
var
  p: PByte;
begin
  if Length(FData) > 1 then
  begin
    p := @FData[1];
    DecodeInt(p, Size - 1, Result);
  end
  else
    Result := 0;
end;

function TQMQTTMessage.GetPosition: Integer;
begin
  Result := IntPtr(FCurrent) - IntPtr(@FData[0]);
end;

function TQMQTTMessage.GetQoSLevel: TQMQTTQoSLevel;
begin
  Result := TQMQTTQoSLevel((FData[0] shr 1) and 3);
end;

function TQMQTTMessage.GetRemainSize: Integer;
begin
  Result := FSize - Cardinal(Position);
end;

function TQMQTTMessage.GetTopicContent: TBytes;
var
  p: PByte;
begin
  if ControlType = ctPublish then
  begin
    p := TopicOriginContent;
    SetLength(Result, Length(FData) - (IntPtr(p) - IntPtr(@FData[0])));
    Move(p^, Result[0], Length(Result));
  end
  else
    SetLength(Result, 0);
end;

function TQMQTTMessage.GetTopicContentSize: Integer;
begin
  if ControlType = ctPublish then
    Result := Length(FData) - (IntPtr(TopicOriginContent) - IntPtr(@FData[0]))
  else
    Result := 0;
end;

function TQMQTTMessage.GetTopicId: Word;
var
  p: PByte;
begin
  case ControlType of
    ctPublish:
      begin
        p := FVarHeader;
        Inc(p, ExchangeByteOrder(PWord(p)^) + 2);
        if QosLevel > qlMax1 then
          // �������ܴ��ڵ�PackageId
          Result := ExchangeByteOrder(PWord(p)^)
        else
          Result := 0;
      end;
    ctPublishAck:
      Result := ExchangeByteOrder(PWord(FVarHeader)^);
    ctPublishRecv, ctPublishRelease, ctPublishDone, ctSubscribe:
      Result := ExchangeByteOrder(PWord(FVarHeader)^)
  else
    Result := 0;
  end;
end;

function TQMQTTMessage.GetTopicName: String;
var
  p: PByte;
  ASize: Word;
begin
  if ControlType = ctPublish then
  begin
    p := FVarHeader;
    ASize := ExchangeByteOrder(PWord(p)^);
    Inc(p, 2);
    Result := qstring.Utf8Decode(PQCharA(p), ASize);
  end
  else
    Result := '';
end;

function TQMQTTMessage.GetTopicOriginContent: PByte;
begin
  if ControlType = ctPublish then
  begin
    Result := FVarHeader;
    Inc(Result, ExchangeByteOrder(PWord(Result)^) + 2);
    if QosLevel > qlMax1 then
      // �������ܴ��ڵ�PackageId
      Inc(Result, 2);
  end
  else
    Result := nil;
end;

function TQMQTTMessage.GetTopicText: String;
var
  p: PByte;
begin
  if ControlType = ctPublish then
  begin
    p := FVarHeader;
    Inc(p, ExchangeByteOrder(PWord(p)^) + 2);
    if QosLevel > qlMax1 then
      // �������ܴ��ڵ�PackageId
      Inc(p, 2);
    Result := qstring.Utf8Decode(PQCharA(p), Length(FData) - (IntPtr(p) - IntPtr(@FData[0])));
  end
  else
    Result := '';
end;

function TQMQTTMessage.GetVarHeaderOffset: Integer;
begin
  Result := IntPtr(FVarHeader) - IntPtr(Bof);
end;

class function TQMQTTMessage.IntEncodedSize(const V: Cardinal): Byte;
begin
  Result := 1;
  if V >= 128 then
  begin
    Inc(Result);
    if V >= 16384 then
    begin
      Inc(Result);
      if V >= 2097152 then
        Inc(Result)
      else if V > 268435455 then
        raise Exception.CreateFmt(STooLargePayload, [V]);
    end;
  end;
end;

function TQMQTTMessage.MoveBy(const ADelta: Integer): PQMQTTMessage;
begin
  Inc(FCurrent, ADelta);
  if FCurrent < Bof then
    FCurrent := Bof
  else if FCurrent > Eof then
    FCurrent := Eof;
  Result := @Self;
end;

procedure TQMQTTMessage.MoveToVarHeader;
begin
  FCurrent := Bof + VarHeaderOffset;
end;

function TQMQTTMessage.NextByte: Byte;
begin
  Result := FCurrent^;
  Inc(FCurrent);
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextBytes(ABuf: Pointer; ALen: Integer): Integer;
begin
  Result := Length(FData) - (IntPtr(FCurrent) - IntPtr(@FData[0]));
  if Result > ALen then
    Result := ALen;
  Move(FCurrent^, ABuf^, Result);
  Inc(FCurrent, Result);
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextBytes(ASize: Integer): TBytes;
begin
  SetLength(Result, ASize);
  if ASize > 0 then
  begin
    Move(FCurrent^, Result[0], ASize);
    Assert(FCurrent <= Eof);
  end;
end;

function TQMQTTMessage.NextDWord(AIsEncoded: Boolean): Cardinal;
begin
  if AIsEncoded then
    Assert(DecodeInt(FCurrent, -1, Result))
  else
  begin
    Result := ExchangeByteOrder(PCardinal(FCurrent)^);
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextFloat(AIsEncoded: Boolean): Double;
var
  T: Int64 absolute Result;
begin
  if AIsEncoded then
    Assert(DecodeInt64(FCurrent, -1, T))
  else
  begin
    Result := ExchangeByteOrder(PCardinal(FCurrent)^);
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextInt(AIsEncoded: Boolean): Integer;
begin
  if AIsEncoded then
    Assert(DecodeInt(FCurrent, -1, Cardinal(Result)))
  else
  begin
    Result := ExchangeByteOrder(PInteger(FCurrent)^);
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextInt64(AIsEncoded: Boolean): Int64;
begin
  if AIsEncoded then
    Assert(DecodeInt64(FCurrent, -1, Result))
  else
  begin
    Result := ExchangeByteOrder(PInt64(FCurrent)^);
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextSingle(AIsEncoded: Boolean): Single;
var
  T: Cardinal absolute Result;
begin
  if AIsEncoded then
    Assert(DecodeInt(FCurrent, -1, T))
  else
  begin
    T := ExchangeByteOrder(PInteger(FCurrent)^);
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextSmallInt(AIsEncoded: Boolean): Smallint;
begin
  if AIsEncoded then
    Result := NextInt(true)
  else
  begin
    Result := ExchangeByteOrder(PSmallint(FCurrent)^);
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextString: String;
var
  ALen, ARemain: Integer;
begin
  ALen := NextWord(false);
  ARemain := RemainSize;
  if ALen > ARemain then
    ALen := ARemain;
  Result := qstring.Utf8Decode(PQCharA(Current), ALen);
  Inc(FCurrent, ALen);
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextTinyInt: Shortint;
begin
  Result := FCurrent^;
  Inc(FCurrent);
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextUInt64(AIsEncoded: Boolean): UInt64;
begin
  if AIsEncoded then
    Assert(DecodeInt64(FCurrent, -1, Int64(Result)))
  else
  begin
    Result := UInt64(ExchangeByteOrder(PInt64(FCurrent)^));
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.NextWord(AIsEncoded: Boolean): Word;
begin
  if AIsEncoded then
    Result := Word(NextInt(true))
  else
  begin
    Result := ExchangeByteOrder(PWord(FCurrent)^);
    Inc(FCurrent, SizeOf(Result));
  end;
  Assert(FCurrent <= Eof);
end;

function TQMQTTMessage.ReloadSize(AKnownBytes: Integer): Boolean;
var
  AVarOffset: Integer;
begin
  if AKnownBytes > 1 then
  begin
    FCurrent := @FData[1];
    Result := DecodeInt(FCurrent, AKnownBytes - 1, FSize);
    if Result then
    begin
      AVarOffset := Position;
      Inc(FSize, Position);
      if Cardinal(Length(FData)) < FSize then
      begin
        SetLength(FData, (FSize + 15) and $FFFFFFF0);
        FCurrent := Bof + AVarOffset;
      end;
      FVarHeader := FCurrent;
    end;
  end
  else
    Result := false;
end;

procedure TQMQTTMessage.SetByte(const AIndex: Integer;

const Value: Byte);
begin
  Assert((AIndex >= 0) and (AIndex < Length(FData)));
  FData[AIndex] := Value;
end;

procedure TQMQTTMessage.SetCapacity(

  const Value: Cardinal);
begin
  if Value > FSize then
  begin
    if (Value and $F) <> 0 then
      SetLength(FData, (Value and $FFFFFFF0) + 16)
    else
      SetLength(FData, Value);
  end;
end;

procedure TQMQTTMessage.SetControlType(

  const AType: TQMQTTControlType);
begin
  Assert(Length(FData) > 0);
  FData[0] := (FData[0] and $0F) or (Ord(AType) shl 4);
end;

procedure TQMQTTMessage.SetHeaderFlags(

  const Index: Integer;

const Value: Boolean);
const
  AMasks: array [0 .. 1] of Byte = (1, 8);
begin
  Assert(Length(FData) > 1);
  if Value then
    FData[0] := FData[0] or AMasks[Index]
  else
    FData[0] := FData[0] and (not AMasks[Index]);
end;

procedure TQMQTTMessage.SetPayloadSize(Value: Cardinal);
var
  AReqSize: Integer;
begin
  AReqSize := SizeOf(Byte) + Value + IntEncodedSize(Value);
  if Length(FData) < AReqSize then
    SetLength(FData, AReqSize);
  FSize := AReqSize;
  FCurrent := @FData[1];
  EncodeInt(FCurrent, Value);
  FVarHeader := FCurrent;
  Assert(FCurrent <= Eof);
end;

procedure TQMQTTMessage.SetPosition(

  const Value: Integer);
begin
  FCurrent := Bof;
  Inc(FCurrent, Value);
  Assert(FCurrent <= Eof);
  if FCurrent < Bof then
    FCurrent := Bof
  else if FCurrent > Eof then
    FCurrent := Eof;
end;

procedure TQMQTTMessage.SetQosLevel(ALevel: TQMQTTQoSLevel);
begin
  Assert(Length(FData) > 0);
  FData[0] := (FData[0] and $F9) or (Ord(ALevel) shl 1);
end;

function TQMQTTMessage.ContentAsHexText: String;
var
  ABuilder: TQStringCatHelperW;
  C, R, L, ARows, ACols: Integer;
  B: Byte;
  T: array [0 .. 15] of Char;
begin
  ABuilder := TQStringCatHelperW.Create;
  try
    L := Length(FData);
    ARows := (L shr 4);
    if (L and $F) <> 0 then
      Inc(ARows);
    ABuilder.Cat('     ');
    for C := 0 to 15 do
      ABuilder.Cat(IntToHex(C, 2)).Cat(' ');
    ABuilder.Cat(SLineBreak);
    for R := 0 to ARows - 1 do
    begin
      ABuilder.Cat(IntToHex(R, 4)).Cat(' ');
      ACols := L - (R shl 4);
      if ACols > 16 then
        ACols := 16;
      for C := 0 to ACols - 1 do
      begin
        B := FData[R * 16 + C];
        Result := Result + IntToHex(B, 2) + ' ';
        if (B >= $20) and (B <= $7E) then
          T[C] := Char(B)
        else
          T[C] := '.';
      end;
      for C := ACols to 15 do
        T[C] := ' ';
      ABuilder.Cat(@T[0], 16).Cat(SLineBreak);
    end;
    Result := ABuilder.Value;
  finally
    FreeAndNil(ABuilder);
  end;
end;

{ TSocketRecvThread }

constructor TSocketRecvThread.Create(AOwner: TQMQTTMessageClient);
begin
  inherited;
  Suspended := false;
end;

procedure TSocketRecvThread.Execute;
begin
  try
    FOwner.DoRecv;
  except
    on E: Exception do

  end;
  if AtomicDecrement(FOwner.FThreadCount) = 0 then
    FOwner.DoCleanup;
end;

{$IFDEF MSWINDOWS}

procedure StartSocket;
var
  AData: WSAData;
begin
  if WSAStartup($202, &AData) <> NO_ERROR then
    RaiseLastOSError();
end;

procedure CleanSocket;
begin
  WSACleanup;
end;
{$ELSE}

procedure StartSocket; inline;
begin
end;

procedure CleanSocket; inline;
begin
end;
{$ENDIF}
{ TTopicHandler }

constructor TTopicHandler.Create(

  const ATopic: String; AHandler: TQMQTTTopicDispatchEvent; AMatchType: TTopicMatchType);
begin
  inherited Create;
  FMatchType := AMatchType;
  FTopic := ATopic;
  if AMatchType = TTopicMatchType.mtRegex then
  begin
    FRegex := TPerlRegex.Create;
    try
      FRegex.RegEx := ATopic;
      FRegex.Compile;
    except
      FreeAndNil(FRegex);
      raise;
    end;
  end;
  FOnDispatch := AHandler;
end;

destructor TTopicHandler.Destroy;
begin
  if Assigned(FRegex) then
    FreeAndNil(FRegex);
  if TMethod(FOnDispatch).Data = Pointer(-1) then
    TQMQTTTopicDispatchEventA(TMethod(FOnDispatch).Code) := nil;
  inherited;
end;

function TTopicHandler.IsMatch(

  const ATopic: String): Boolean;
  function PatternMatch: Boolean;
  var
    ps, pd: PChar;
    ARegex: String;
  begin
    // �Ȳ�ʵ�־�����㷨��ת��Ϊ����ƥ��
    if not Assigned(FRegex) then
    begin
      FRegex := TPerlRegex.Create;
      SetLength(ARegex, Length(FTopic) shl 2);
      ps := PChar(FTopic);
      pd := PChar(ARegex);
      while ps^ <> #0 do
      begin
        if ps^ = '#' then
        begin
          pd[0] := '.';
          pd[1] := '*';
          Inc(pd, 2);
        end
        else if ps^ = '+' then
        begin
          pd[0] := '[';
          pd[1] := '^';
          pd[2] := '/';
          pd[3] := ']';
          pd[4] := '+';
          Inc(pd, 5);
        end
        else if ps^ = '$' then
        begin
          pd^ := '.';
          Inc(pd);
        end
        else
        begin
          pd^ := ps^;
          Inc(pd);
        end;
        Inc(ps);
      end;
      pd^ := #0;
      FRegex.RegEx := PChar(ARegex);
      FRegex.Compile;
    end;
    FRegex.Subject := ATopic;
    Result := FRegex.Match;
  end;

begin
  if FMatchType = mtRegex then
  begin
    FRegex.Subject := ATopic;
    Result := FRegex.Match;
  end
  else if FMatchType = mtPattern then
    Result := PatternMatch
  else
    Result := true;
end;

{ TSocketThread }

constructor TSocketThread.Create(AOwner: TQMQTTMessageClient);
begin
  inherited Create(true);
  FOwner := AOwner;
  FreeOnTerminate := true;
  AtomicIncrement(AOwner.FThreadCount);
end;

{ TSocketSendThread }

constructor TSocketSendThread.Create(AOwner: TQMQTTMessageClient);
begin
  inherited;
  FNotifyEvent := TEvent.Create(nil, false, false, '');
  Suspended := false;
end;

destructor TSocketSendThread.Destroy;
begin
  FreeAndNil(FNotifyEvent);
  inherited;
end;

procedure TSocketSendThread.Execute;
var
  AFirst, ANext: PQMQTTMessage;
  procedure Cleanup;
  begin
    while Assigned(AFirst) do
    begin
      ANext := AFirst.Next;
      Dispose(AFirst);
      AFirst := ANext;
    end;
    if Assigned(FFirst) then
    begin
      AFirst := FFirst;
      FFirst := nil;
      FLast := nil;
      Cleanup;
    end;
  end;

begin
  try
    while not Terminated do
    begin
      if FNotifyEvent.WaitFor = wrSignaled then
      begin
        if Terminated then
          Break;
        if not Assigned(AFirst) then
        begin
          // ȫ������
          FOwner.Lock;
          try
            AFirst := FFirst;
            FFirst := nil;
            FLast := nil;
          finally
            FOwner.Unlock;
          end;
        end;
        while Assigned(AFirst) do
        begin
          ANext := AFirst.Next;
          if FOwner.DoSend(AFirst) then
            AFirst := ANext
          else
            Break;
        end;
      end;
    end;
  finally
    Cleanup;
    if AtomicDecrement(FOwner.FThreadCount) = 0 then
      FOwner.DoCleanup;
  end;
end;

procedure TSocketSendThread.Post(AMessage: PQMQTTMessage);
begin
  FOwner.Lock;
  try
    if Assigned(FLast) then
      FLast.Next := AMessage;
    if not Assigned(FFirst) then
      FFirst := AMessage;
    FLast := AMessage;
  finally
    FOwner.Unlock;
    FNotifyEvent.SetEvent;
  end;
end;

procedure TSocketSendThread.Send(AMessage: PQMQTTMessage);
var
  AEvent: TEvent;
begin
  AEvent := TEvent.Create(nil, false, false, '');
  try
    AMessage.FWaitEvent := AEvent;
    Post(AMessage);
  finally
    FreeAndNil(AEvent);
  end;
end;

{ TQMQTT5Props }

function TQMQTT5Props.Copy: TQMQTT5Props;
begin
  Result := TQMQTT5Props.Create;
  Result.Replace(Self);
end;

constructor TQMQTT5Props.Create;
begin
  SetLength(FItems, 42);
end;

destructor TQMQTT5Props.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
  begin
    if (MQTT5PropTypes[I].DataType in [ptString, ptBinary]) and Assigned(FItems[I].AsString) then
    begin
      if MQTT5PropTypes[I].DataType = ptString then
        Dispose(FItems[I].AsString)
      else
        Dispose(FItems[I].AsBytes);
    end;
  end;
  inherited;
end;

function TQMQTT5Props.GetAsInt(const APropId: Byte): Cardinal;
begin
  case MQTT5PropTypes[APropId - 1].DataType of
    ptByte:
      Result := FItems[APropId - 1].AsByte;
    ptWord:
      Result := FItems[APropId - 1].AsWord;
    ptInt, ptVarInt:
      Result := FItems[APropId - 1].AsInteger;
    ptString:
      begin
        if Assigned(FItems[APropId - 1].AsString) then
          Result := StrToInt(FItems[APropId - 1].AsString^)
        else
          raise Exception.Create('��֧�ֵ�����ת��');
      end
  else
    raise Exception.Create('��֧�ֵ�����ת��');
  end;
end;

function TQMQTT5Props.GetAsString(const APropId: Byte): String;
begin
  case MQTT5PropTypes[APropId - 1].DataType of
    ptByte:
      Result := IntToStr(FItems[APropId - 1].AsByte);
    ptWord:
      Result := IntToStr(FItems[APropId - 1].AsWord);
    ptInt, ptVarInt:
      Result := IntToStr(FItems[APropId - 1].AsInteger);
    ptString:
      begin
        if Assigned(FItems[APropId - 1].AsString) then
          Result := FItems[APropId - 1].AsString^
        else
          SetLength(Result, 0);
      end;
    ptBinary:
      begin
        if Assigned(FItems[APropId - 1].AsBytes) then
          Result := BinToHex(FItems[APropId - 1].AsBytes^)
        else
          SetLength(Result, 0);
      end
  else
    raise Exception.Create('��֧�ֵ�����ת��');
  end;
end;

function TQMQTT5Props.GetAsVariant(const APropId: Byte): Variant;
var
  p: PByte;
begin
  case MQTT5PropTypes[APropId - 1].DataType of
    ptByte:
      Result := FItems[APropId - 1].AsByte;
    ptWord:
      Result := FItems[APropId - 1].AsWord;
    ptInt, ptVarInt:
      Result := FItems[APropId - 1].AsInteger;
    ptString:
      begin
        if Assigned(FItems[APropId - 1].AsString) then
          Result := Utf8Decode(FItems[APropId - 1].AsString^)
        else
          Result := '';
      end;
    ptBinary:
      begin
        if Assigned(FItems[APropId - 1].AsBytes) then
        begin
          Result := VarArrayCreate([0, Length(FItems[APropId - 1].AsBytes^) - 1], varByte);
          p := VarArrayLock(Result);
          Move(FItems[APropId - 1].AsBytes^[0], p^, Length(FItems[APropId - 1].AsBytes^));
          VarArrayUnlock(Result);
        end
        else
          Result := Null;
      end
  else
    raise Exception.Create('��֧�ֵ�����ת��');
  end;
end;

function TQMQTT5Props.GetDataSize(const APropId: Byte): Integer;
var
  AType: PQMQTT5PropType;
begin
  AType := @MQTT5PropTypes[APropId - 1];
  Result := AType.DataSize;
  if Result < 0 then
  begin
    if AType.DataType = ptVarInt then
      Result := TQMQTTMessage.IntEncodedSize(AsInt[APropId])
    else if AType.DataType = ptString then
      Result := FItems[APropId - 1].AsString^.Length
    else if AType.DataType = ptBinary then
      Result := Length(FItems[APropId - 1].AsBytes^);
  end;
end;

function TQMQTT5Props.GetIsSet(const APropId: Byte): Boolean;
begin
  Result := FItems[APropId - 1].IsSet;
end;

function TQMQTT5Props.GetMinMaxId(const Index: Integer): Byte;
begin
  if Index = 0 then
    Result := 1
  else
    Result := Length(FItems);
end;

function TQMQTT5Props.GetPayloadSize: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FItems) do
  begin
    if FItems[I].IsSet then
      Inc(Result, DataSize[I + 1] + 1);
  end;
  Inc(Result, TQMQTTMessage.IntEncodedSize(Result));
end;

function TQMQTT5Props.GetPropTypes(const APropId: Byte): PQMQTT5PropType;
begin
  Result := @MQTT5PropTypes[APropId - 1];
end;

procedure TQMQTT5Props.ReadProps(const AMessage: PQMQTTMessage);
var
  APropLen: Cardinal;
  pe: PByte;
  I: Integer;
  APropId: Byte;
begin
  APropLen := AMessage.NextDWord(true);
  pe := AMessage.Current + APropLen;
  for I := 0 to High(FItems) do
    FItems[I].IsSet := false;
  while AMessage.Current < pe do
  begin
    APropId := AMessage.NextByte;
    if APropId in [1 .. 42] then
    begin
      with FItems[APropId - 1] do
      begin
        case MQTT5PropTypes[APropId - 1].DataType of
          ptByte:
            AsByte := AMessage.NextByte;
          ptWord:
            AsWord := AMessage.NextWord(false);
          ptInt:
            AsInteger := AMessage.NextDWord(false);
          ptVarInt:
            AsInteger := AMessage.NextDWord(true);
          ptString:
            begin
              if not Assigned(AsString) then
                New(AsString);
              AsString^.Length := AMessage.NextWord(false);
              AsString^.IsUtf8 := true;
              AMessage.NextBytes(PQCharA(AsString^), AsString^.Length);
            end;
          ptBinary:
            begin
              if not Assigned(AsBytes) then
                New(AsBytes);
              SetLength(AsBytes^, AMessage.NextWord(false));
              AMessage.NextBytes(@AsBytes^[0], Length(AsBytes^));
            end;
        end;
        IsSet := true;
      end;
    end;
  end;
end;

procedure TQMQTT5Props.Replace(AProps: TQMQTT5Props);
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
  begin
    if AProps.FItems[I].IsSet then
    begin
      case MQTT5PropTypes[I].DataType of
        ptString:
          begin
            if not Assigned(FItems[I].AsString) then
              New(FItems[I].AsString);
            FItems[I].AsString^ := AProps.FItems[I].AsString^;
          end;
        ptBinary:
          begin
            if not Assigned(FItems[I].AsBytes) then
              New(FItems[I].AsBytes);
            FItems[I].AsBytes^ := AProps.FItems[I].AsBytes^;
          end
      else
        FItems[I].AsInteger := AProps.FItems[I].AsInteger;
      end;
    end;
  end;
end;

procedure TQMQTT5Props.SetAsInt(const APropId: Byte; const Value: Cardinal);
begin
  FItems[APropId - 1].IsSet := true;
  case MQTT5PropTypes[APropId - 1].DataType of
    ptByte:
      FItems[APropId - 1].AsByte := Value;
    ptWord:
      FItems[APropId - 1].AsWord := Value;
    ptInt, ptVarInt:
      FItems[APropId - 1].AsInteger := Value;
    ptString:
      begin
        if not Assigned(FItems[APropId - 1].AsString) then
          New(FItems[APropId - 1].AsString);
        FItems[APropId - 1].AsString^ := IntToStr(Value);
      end
  else
    begin
      FItems[APropId - 1].IsSet := false;
      raise Exception.Create('��֧�ֵ�����ת��');
    end;
  end;
end;

procedure TQMQTT5Props.SetAsString(const APropId: Byte; const Value: String);
begin
  FItems[APropId - 1].IsSet := true;
  case MQTT5PropTypes[APropId - 1].DataType of
    ptByte:
      FItems[APropId - 1].AsByte := Byte(StrToInt(Value));
    ptWord:
      FItems[APropId - 1].AsWord := Word(StrToInt(Value));
    ptInt, ptVarInt:
      FItems[APropId - 1].AsInteger := Cardinal(StrToInt(Value));
    ptString:
      begin
        if not Assigned(FItems[APropId - 1].AsString) then
          New(FItems[APropId - 1].AsString);
        FItems[APropId - 1].AsString^ := qstring.Utf8Encode(Value);
      end;
    ptBinary:
      begin
        if not Assigned(FItems[APropId - 1].AsBytes) then
          New(FItems[APropId - 1].AsBytes);
        FItems[APropId - 1].AsBytes^ := qstring.Utf8Encode(Value);
      end;
  end;
end;

procedure TQMQTT5Props.SetAsVariant(const APropId: Byte; const Value: Variant);
begin
  FItems[APropId - 1].IsSet := true;
  case MQTT5PropTypes[APropId - 1].DataType of
    ptByte:
      FItems[APropId - 1].AsByte := Value;
    ptWord:
      FItems[APropId - 1].AsWord := Value;
    ptInt, ptVarInt:
      FItems[APropId - 1].AsInteger := Value;
    ptString:
      begin
        if not Assigned(FItems[APropId - 1].AsString) then
          New(FItems[APropId - 1].AsString);
        FItems[APropId - 1].AsString^ := qstring.Utf8Encode(VarToStr(Value));
      end;
    ptBinary:
      begin
        if not Assigned(FItems[APropId - 1].AsBytes) then
          New(FItems[APropId - 1].AsBytes);
        SetLength(FItems[APropId - 1].AsBytes^, VarArrayHighBound(Value, 1) + 1);
        Move(VarArrayLock(Value)^, FItems[APropId - 1].AsBytes^[0], Length(FItems[APropId - 1].AsBytes^));
        VarArrayUnlock(Value);
      end;
  end;
end;

procedure TQMQTT5Props.WriteProps(AMessage: PQMQTTMessage);
var
  I: Integer;
  ASize: Cardinal;
  APropType: PQMQTT5PropType;
begin
  ASize := 0;
  for I := 0 to High(FItems) do
  begin
    if FItems[I].IsSet then
      Inc(ASize, DataSize[I + 1] + 1);
  end;
  AMessage.Cat(ASize, true);
  for I := 0 to High(FItems) do
  begin
    if FItems[I].IsSet then
    begin
      APropType := @MQTT5PropTypes[I];
      AMessage.Cat(APropType.Id);
      case APropType.DataType of
        ptByte:
          AMessage.Cat(FItems[I].AsByte);
        ptWord:
          AMessage.Cat(FItems[I].AsWord);
        ptInt:
          AMessage.Cat(FItems[I].AsInteger);
        ptVarInt:
          AMessage.Cat(FItems[I].AsInteger, true);
        ptString:
          AMessage.Cat(FItems[I].AsString^);
        ptBinary:
          AMessage.Cat(FItems[I].AsBytes^);
      end;
    end;
  end;
end;

{ TQMQTT5PropType }

function TQMQTT5PropType.GetDataSize: Integer;
const
  DataSizes: array [TQMQTT5PropDataType] of Integer = (0, 1, 2, 4, -4, -1, -1);
begin
  Result := DataSizes[DataType];
end;

{ TQMQTTSubscribeResult }

function TQMQTTSubscribeResult.GetSuccess: Boolean;
begin
  Result := (ErrorCode = 0);
end;

initialization

StartSocket;

finalization

if Assigned(_DefaultClient) then
  FreeAndNil(_DefaultClient);
CleanSocket;

end.
