unit Launch2027.consts;

interface

const

AudioFiles: array[1..8] of string =
(
    'GameConversationsAudioNPCBarks',
    'GameConversationsAudioCutScenes',
    'GameConversationsAudioChapter6',
    'GameConversationsAudioChapter5',
    'GameConversationsAudioChapter4',
    'GameConversationsAudioChapter1',
    'GameConversationsAudioChapter3',
    'GameConversationsAudioChapter2'
);

MapFiles: array[1..3] of string =
(
    '04_Vladimir',
    '05_Titan',
    '06_TitanHack'
);

    GamePath = 'System\2027.exe';
    RunningPath = 'System\Running.ini';

    GameConfigPath = '\2027\System\2027.ini';
    UserConfigPath = '\2027\System\2027User.ini';
    EnbConfigPath = '\System\enbseries.ini';

    LanguageRussian = 'rus';
    LanguageEnglish = 'eng';

    WebSite_rus =  'http://project2027.com/ru/';
    WebSite_eng = 'http://project2027.com/en/';

    Forum_rus = 'http://planetdeusex.ru/forum/index.php?showforum=3';
    Forum_eng = 'http://www.dxalpha.com/forum/viewforum.php?f=141';

    FileSizesRus = 112;
    FileSizesEng = 127;

resourcestring
    // English
    strLanguageLabel = 'Game/launcher language:';
    strVOLanguageLabel = 'Voiceover language:';
    strResolutionLabel = 'Screen resolution:';
    strRenderDevice = 'Rendering device:';

    strRunInWindow = 'Run in windowed mode';
    strEnbLabel = 'Use advanced effects';

    strStartButton = 'Launch game';
    strVOChangeLabel = 'Apply this language';

    strResolutionCustomLabel = 'Custom...';

    strErrorInvalidDir = 'Invalid install path. Please reinstall 2027.';
    strErrorInvalidVersion = 'Invalid version of Deus Ex. Please install the 1.112fm patch.';

    strWebsiteLabel = 'Website';
    strForumLabel = 'Forum';

    strVoiceverChanged = 'Successfully changed voiceover language.';


    // �������
    rusLanguageLabel = '���� ���� � ��������:';
    rusVOLanguageLabel = '���� �����������:';
    rusResolutionLabel = '���������� ������:';
    rusRenderDevice = '���������� ����������:';

    rusRunInWindow = '��������� � ����';
    rusEnbLabel = '������������ ����� �������';

    rusStartButton = '��������� ����';
    rusVOChangeLabel = '�������� ���� ����';

    rusResolutionCustomLabel = '������...';

    rusErrorInvalidDir = 'Deus Ex �� ������. ��������� ���� �� �����, � ������� �� ���������� 2027.';
    rusErrorInvalidVersion = '������ ������ Deus Ex. ���������� ���� 1.112fm.';

    rusWebsiteLabel = '����';
    rusForumLabel = '�����';

    rusVoiceverChanged = '���� ����������� ������.';


implementation

end.
