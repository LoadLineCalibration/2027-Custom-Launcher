unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Imaging.pngimage, Vcl.StdCtrls, system.IOUtils,
  Launch2027.consts, system.IniFiles, system.Generics.Collections, system.Generics.Defaults, System.StrUtils,
  Launch2027.Utils, Launch2027.Classes, ES.Labels, System.Types, System.UITypes;

type
  TfrmMain = class(TForm)
    Image1: TImage;
    cmbScreenRes: TComboBox;
    edtResX: TEdit;
    edtResY: TEdit;
    lblResX: TLabel;
    lblScreenRes: TLabel;
    lblLanguage: TLabel;
    cmbGameLang: TComboBox;
    chkRunInWindow: TCheckBox;
    lblRunInWindow: TLabel;
    btnLaunchGame: TButton;
    cmbRenderDevices: TComboBox;
    lblRenderDevice: TLabel;
    lblVOLanguage: TLabel;
    cmbVoiceoverLang: TComboBox;
    chkEnhancedGraphics: TCheckBox;
    lblEnhancedGraphics: TLabel;
    btnSwitchVO: TButton;
    lnkWebSite: TEsLinkLabel;
    lnkForum: TEsLinkLabel;
    lblSingleCore: TLabel;
    chkSingleCore: TCheckBox;

    // new procedures
    procedure FindIntFiles(const Dir: string);
    procedure ParseIntFile(const IntFileName: string);
    procedure FillScreenResolutions();
    procedure ToggleCustomResolutionControls(bShow: Boolean);
    procedure LaunchGame();
    procedure ReadGameSettings();
    procedure SaveGameSettings();
    procedure SwitchVoiceLanguage(Language: string);
    procedure TryToDetectVoiceoverLanguage(); //по размеру файлов, другого способа я не знаю.
    procedure StartupCheck();

    procedure FormCreate(Sender: TObject);
    procedure cmbScreenResChange(Sender: TObject);
    procedure lblRunInWindowClick(Sender: TObject);
    procedure btnLaunchGameClick(Sender: TObject);
    procedure lblEnhancedGraphicsClick(Sender: TObject);
    procedure cmbRenderDevicesDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure cmbRenderDevicesChange(Sender: TObject);
    procedure btnSwitchVOClick(Sender: TObject);
    procedure cmbGameLangChange(Sender: TObject);
    procedure lblSingleCoreClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}


procedure TfrmMain.btnLaunchGameClick(Sender: TObject);
begin
    SaveGameSettings();
    LaunchGame();
end;

procedure TfrmMain.ParseIntFile(const IntFileName: string);
var
    IntFileContent: TStringList;
    Line: string;
    ObjectName, ClassCaption: string;
    I: Integer;
    bSectionFound: Boolean;
begin
    IntFileContent := TStringList.Create;
    try
        IntFileContent.LoadFromFile(IntFileName);

        // Сначала найдем Object и проверим MetaClass
        for I := 0 to IntFileContent.Count - 1 do
        begin
            Line := Trim(IntFileContent[I]);

            // Пропускаем комментарии и пустые строки
            if (Line = '') or (Line.StartsWith('//')) or (Line.StartsWith(';')) then
                Continue;

            if Line.StartsWith('Object=(Name=') and Line.Contains('MetaClass=Engine.RenderDevice') then
            begin
                // Извлекаем Object Name
                ObjectName := Copy(Line, Pos('Name=', Line) + 5, Pos(',', Line, Pos('Name=', Line)) - Pos('Name=', Line) - 5);
                Break;
            end;
        end;

        if ObjectName = '' then
            Exit; // Если Object не найден, выходим

        // Найдем секцию и ClassCaption
        bSectionFound := False;
        for I := 0 to IntFileContent.Count - 1 do
        begin
            Line := Trim(IntFileContent[I]);

            if bSectionFound then
            begin
                if Line.StartsWith('[') then
                    Break; // Конец секции

                if Line.StartsWith('ClassCaption=') then
                begin
                    ClassCaption := Copy(Line, Pos('=', Line) + 1, MaxInt);
                    Break;
                end;
            end
            else if Line = '[' + Copy(ObjectName, Pos('.', ObjectName) + 1, MaxInt) + ']' then
            begin
                bSectionFound := True;
            end;
        end;

        if ClassCaption <> '' then
        begin
            ClassCaption := StringReplace(ClassCaption, '"', '', [rfReplaceAll]);
            cmbRenderDevices.Items.AddPair(ClassCaption, ObjectName);
        end;

    finally
        IntFileContent.Free();
    end;
end;

procedure TfrmMain.ReadGameSettings(); // прочесть файлы конфигурации
begin
    var EnbIni := TIniFile.Create(ExtractFilePath(ParamStr(0)) + EnbConfigPath);
    var GameIni := TIniFile.Create(ExtractFilePath(ParamStr(0)) + GameConfigPath);

    try
        // ENB effects
        var bENBEnabled := EnbIni.ReadBool('GLOBAL', 'UseEffect', True);
        chkEnhancedGraphics.Checked := bENBEnabled;

        // language
        var GameLang := GameIni.ReadString('Engine.Engine', 'Language', 'rus');
        if GameLang = 'rus' then cmbGameLang.ItemIndex := 0
        else if GameLang = 'eng' then cmbGameLang.ItemIndex := 1;

        cmbGameLangChange(self);

        TryToDetectVoiceoverLanguage();

        // rendering device
        var RenDev := GameIni.ReadString('Engine.Engine', 'GameRenderDevice', 'OpenGlDrv.OpenGlRenderDevice');

        for var i := 0 to cmbRenderDevices.Items.Count - 1 do
        begin
            if LowerCase(cmbRenderDevices.Items.ValueFromIndex[i]) = LowerCase(RenDev) then
            begin
                cmbRenderDevices.ItemIndex := i;
                Break;
            end
        end;

        cmbRenderDevicesChange(self);

        // windowed mode/full screen
        var bRunInWindow := GameIni.ReadString('WinDrv.WindowsClient','StartupFullscreen', 'True');
        if UpperCase(bRunInWindow) = 'TRUE' then
            chkRunInWindow.Checked := False
        else if UpperCase(bRunInWindow) = 'FALSE' then
            chkRunInWindow.Checked := True;

        chkSingleCore.Checked := GameIni.ReadBool('2027Launcher', 'chkSingleCore.Checked', True);

        // screen resolution
        var ResX := GameIni.ReadInteger('WinDrv.WindowsClient', 'FullscreenViewportX', DEFAULT_RES_X);
        var ResY := GameIni.ReadInteger('WinDrv.WindowsClient', 'FullscreenViewportY', DEFAULT_RES_Y);
        var ResStr := IntToStr(ResX) + 'x' + IntToStr(ResY);

        var bFound := False;
        for var i := 0 to cmbScreenRes.Items.Count - 1 do
        begin
            if cmbScreenRes.Items[i] = ResStr then
            begin
                cmbScreenRes.ItemIndex := i;
                bFound := True;
                Break;
            end;
        end;

        if bFound=False then
        begin
            cmbScreenRes.ItemIndex := 0;
            edtResX.Text := IntToStr(ResX);
            edtResY.Text := IntToStr(ResY);
        end;

        cmbScreenResChange(self);

    finally
        EnbIni.Free();
        GameIni.Free();
    end;
end;

procedure TfrmMain.SaveGameSettings();
var
    Res: TScreenResolution;
    xPos: Integer;
    fov: Double;
begin
    var EnbIni := TIniFile.Create(ExtractFilePath(ParamStr(0)) + EnbConfigPath);
    var GameIni := TIniFile.Create(ExtractFilePath(ParamStr(0)) + GameConfigPath);
    var GameUserIni := TIniFile.Create(ExtractFilePath(ParamStr(0)) + UserConfigPath);

    try
        // ENB effects
        EnbIni.WriteBool('GLOBAL', 'UseEffect', chkEnhancedGraphics.Checked);

        // Rendering device
        var RenDev := cmbRenderDevices.Items.ValueFromIndex[cmbRenderDevices.ItemIndex];
        GameIni.WriteString('Engine.Engine','GameRenderDevice', RenDev);

        // FullScreen?
        case chkRunInWindow.Checked of
            True:  GameIni.WriteString('WinDrv.WindowsClient', 'StartupFullscreen', 'False');
            False: GameIni.WriteString('WinDrv.WindowsClient', 'StartupFullscreen', 'True');
        end;

        // Single CPU core?
        GameIni.WriteBool('2027Launcher', 'chkSingleCore.Checked', chkSingleCore.Checked);


        // Screen resolution
        if cmbScreenRes.ItemIndex > 0 then
        begin
            var SelectedRes := cmbScreenRes.Items[cmbScreenRes.ItemIndex];
            xPos := Pos('x',SelectedRes);
            if xPos > 0 then
            begin
                Res.Width := StrToInt(Copy(SelectedRes, 1, xPos - 1));
                Res.Height := StrToInt(Copy(SelectedRes, xPos + 1, Length(SelectedRes) - xPos));
            end;

            GameIni.WriteInteger('WinDrv.WindowsClient', 'WindowedViewportX', Res.Width);
            GameIni.WriteInteger('WinDrv.WindowsClient', 'WindowedViewportY', Res.Height);
            GameIni.WriteInteger('WinDrv.WindowsClient', 'FullscreenViewportX', Res.Width);
            GameIni.WriteInteger('WinDrv.WindowsClient', 'FullscreenViewportY', Res.Height);
        end
        else if cmbScreenRes.ItemIndex = 0 then
        begin // Если в полях пусто или меньше минимального, то запросим нативное разрешение и установим его.
            if ((edtResX.Text = '') or (edtResY.Text = '')) or
               ((StrToInt(edtResX.Text) < 640) or (StrToInt(edtResY.Text) < 480)) then
            begin
                edtResX.Text := GetSystemMetrics(SM_CXSCREEN).ToString; // The width of the screen of the primary display monitor, in pixels.
                edtResY.Text := GetSystemMetrics(SM_CYSCREEN).ToString;

                Res.Width  := StrToInt(edtResX.text);
                Res.Height := StrToInt(edtResY.text);
            end;
        end;

        // Language + bShowItemArticles
        case cmbGameLang.ItemIndex of
            0:begin
                GameIni.WriteString('Engine.Engine', 'Language', 'rus');
                GameUserIni.WriteString('DeusEx.DeusExPlayer', 'bShowItemArticles', 'False');
            end;

            1: begin
                GameIni.WriteString('Engine.Engine', 'Language', 'eng');
                GameUserIni.WriteString('DeusEx.DeusExPlayer', 'bShowItemArticles', 'True');
            end;
        end;

        // FOV
        fov := CalculateFov(Res);
        GameUserIni.WriteFloat('Engine.PlayerPawn', 'DesiredFOV', fov);
        GameUserIni.WriteFloat('Engine.PlayerPawn', 'DefaultFOV', fov);


    finally
        EnbIni.Free();
        GameIni.Free();
        GameUserIni.Free();
    end;
end;

procedure TfrmMain.StartupCheck();
begin
    var SystemDir := ExtractFilePath(ParamStr(0)) + 'System\';

    if (FileExists(SystemDir + 'DeusEx.exe') = False) or
        (FileExists(SystemDir + '2027.exe') = False) then
    begin
        MessageDlg(strErrorInvalidDir + #13#10 + rusErrorInvalidDir,  mtError, [mbOK], 0);
        Application.Terminate();
    end;

    if FileExists(SystemDir + 'UBrowser.u') = False then
    begin
        MessageDlg(strErrorInvalidVersion + #13#10 + rusErrorInvalidVersion,  mtError, [mbOK], 0);
        Application.Terminate();
    end;
end;

procedure TfrmMain.SwitchVoiceLanguage(Language: string);
var
    VoiceoverPackageLangExt: string;
    MapsLangExt: string;
    SourceFile, DestFile: string;
begin
    var SystemDir := ExtractFilePath(ParamStr(0)) + '2027\System\';
    var MapsDir := ExtractFilePath(ParamStr(0)) + '2027\Maps\';

    // Определение суффикса языка
    if Language = 'ru' then
    begin
        VoiceoverPackageLangExt := '.rus_u';
        MapsLangExt := '.rus_dx';
    end
    else
    begin
        VoiceoverPackageLangExt := '.eng_u';
        MapsLangExt := '.eng_dx';
    end;


    try // Копируем озвучивание
        for var i := 1 to Length(AudioFiles) do
        begin
            SourceFile := SystemDir + AudioFiles[i] + VoiceoverPackageLangExt;
            DestFile := SystemDir + AudioFiles[i] + '.u';

            // Копирование файла с перезаписью
            if FileExists(SourceFile) then
            begin
                TFile.Copy(SourceFile, DestFile, True);
            end
            else
            begin
                raise Exception.CreateFmt('File not found: %s', [SourceFile]);
            end;
        end;

        // И карты, для каждого языка свои задержки CameraPoints
        for var m := 1 to Length(MapFiles) do
        begin
            SourceFile := MapsDir + MapFiles[m] + MapsLangExt;
            DestFile := MapsDir + MapFiles[m] + '.dx';

            // Копирование файла с перезаписью
            if FileExists(SourceFile) then
            begin
                TFile.Copy(SourceFile, DestFile, True);
            end
            else
            begin
                raise Exception.CreateFmt('File not found: %s', [SourceFile]);
            end;
        end;

        if cmbGameLang.ItemIndex = 0 then
            MessageDlg(rusVoiceverChanged,  mtInformation, [mbOK], 0)
        else
            MessageDlg(strVoiceverChanged,  mtInformation, [mbOK], 0)

    except
        on E: Exception do
        begin
            MessageDlg('Failed to change voiceover language: ' + E.Message,  mtError, [mbOK], 0);
        end;
    end;
end;

procedure TfrmMain.FindIntFiles(const Dir: string);
var
    SearchRec: TSearchRec;
begin
    if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*.int', faAnyFile, SearchRec) = 0 then
    begin
        repeat
            ParseIntFile(IncludeTrailingPathDelimiter(Dir) + SearchRec.Name);
        until FindNext(SearchRec) <> 0;

        FindClose(SearchRec);
    end;
end;

procedure TfrmMain.btnSwitchVOClick(Sender: TObject);
begin
    if cmbVoiceoverLang.ItemIndex = 0 then
        SwitchVoiceLanguage('ru')
    else
        SwitchVoiceLanguage('en');
end;

procedure TfrmMain.cmbGameLangChange(Sender: TObject);
begin
    case cmbGameLang.ItemIndex of
        0: begin
            lblLanguage.Caption := rusLanguageLabel;
            lblVOLanguage.Caption := rusVOLanguageLabel;
            lblScreenRes.Caption := rusResolutionLabel;
            lblRenderDevice.Caption := rusRenderDevice;

            lblRunInWindow.Caption := rusRunInWindow;
            lblEnhancedGraphics.Caption := rusEnbLabel;
            lblSingleCore.Caption := rusSingleCPUCore;

            btnLaunchGame.Caption := rusStartButton;
            btnSwitchVO.Caption := rusVOChangeLabel;

            cmbScreenRes.Items[0] := rusResolutionCustomLabel;

            lnkWebSite.Url := WebSite_rus;
            lnkWebSite.Hint := WebSite_rus;
            lnkWebSite.Caption := rusWebsiteLabel;

            lnkForum.Url := Forum_rus;
            lnkForum.Hint := Forum_rus;
            lnkForum.Caption := rusForumLabel;
        end;

        1:begin
            lblLanguage.Caption := strLanguageLabel;
            lblVOLanguage.Caption := strVOLanguageLabel;
            lblScreenRes.Caption := strResolutionLabel;
            lblRenderDevice.Caption := strRenderDevice;

            lblRunInWindow.Caption := strRunInWindow;
            lblEnhancedGraphics.Caption := strEnbLabel;
            lblSingleCore.Caption := strSingleCPUCore;

            btnLaunchGame.Caption := strStartButton;
            btnSwitchVO.Caption := strVOChangeLabel;

            cmbScreenRes.Items[0] := strResolutionCustomLabel;

            lnkWebSite.Url := WebSite_eng;
            lnkWebSite.Hint := WebSite_eng;
            lnkWebSite.Caption := strWebsiteLabel;

            lnkForum.Url := Forum_eng;
            lnkForum.Hint := Forum_eng;
            lnkForum.Caption := strForumLabel;
        end;
    end;
end;

procedure TfrmMain.cmbRenderDevicesChange(Sender: TObject);
begin
    var ItemIdx := cmbRenderDevices.ItemIndex;

    if ItemIdx = -1 then Exit();

    chkEnhancedGraphics.Enabled := cmbRenderDevices.Items.ValueFromIndex[ItemIdx] = 'D3D9Drv.D3D9RenderDevice';
    lblEnhancedGraphics.Enabled := chkEnhancedGraphics.Enabled;
end;

procedure TfrmMain.cmbRenderDevicesDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
    with (Control as TComboBox).Canvas do
    begin
        Font.Name := 'Verdana';
        Font.Size := 10;

        if (odSelected in State) then
        begin
            Font.Color := clHighlightText;
            Brush.Style := bsClear;
            Brush.Color := clHighlight;
            FillRect(Rect);
        end else
        begin
            Font.Color := clBtnText;
            Brush.Style := bsSolid;
            FillRect(Rect);
        end;

        DrawText(cmbRenderDevices.Canvas.Handle, cmbRenderDevices.Items.KeyNames[Index], -1, Rect, DT_EDITCONTROL or DT_WORDBREAK);
    end;
end;

procedure TfrmMain.cmbScreenResChange(Sender: TObject);
begin
    if cmbScreenRes.Items.Count > 0 then
        ToggleCustomResolutionControls(cmbScreenRes.ItemIndex < 1);
end;

procedure TfrmMain.FillScreenResolutions();
var
    DevMode: TDeviceMode;
    i: Integer;
    Resolutions: TList<string>;
begin
    Resolutions := TList<string>.Create();

    try
        cmbScreenRes.Items.Add('Custom...');

        i := 0;
        while EnumDisplaySettings(nil, i, DevMode) do
        begin
            // Создание строки для разрешения
            var resolution := Format('%dx%d', [DevMode.dmPelsWidth, DevMode.dmPelsHeight]);

            // Добавление разрешения в список, если оно ещё не добавлено
            if Resolutions.IndexOf(resolution) = -1 then
                Resolutions.Add(resolution);

            Inc(i);
        end;

        // Всё это только для того чтобы упорядочить список как мне больше нравится
        Resolutions.Sort(TComparer<string>.Construct(
        function(const Left, Right: string): Integer
        var
            LeftWidth, LeftHeight, RightWidth, RightHeight: Integer;
        begin
            // Парсинг ширины и высоты из строки
            LeftWidth := StrToIntDef(Left.Split(['x'])[0], 0);
            LeftHeight := StrToIntDef(Left.Split(['x'])[1], 0);
            RightWidth := StrToIntDef(Right.Split(['x'])[0], 0);
            RightHeight := StrToIntDef(Right.Split(['x'])[1], 0);

            // Сравнение ширины
            if LeftWidth < RightWidth then
                Result := -1
            else if LeftWidth > RightWidth then
                Result := 1
            else
                // Если ширина равна, сравнение высоты
                if LeftHeight < RightHeight then
                    Result := -1
                else if LeftHeight > RightHeight then
                    Result := 1
                else
                    Result := 0;
        end));

        // Добавление отсортированных разрешений в комбинированный список
        for var item in Resolutions do
            cmbScreenRes.Items.Add(item);

    finally
        Resolutions.Free();
    end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
    StartupCheck(); // Проверка наличия файлов, если нет, выходим.

    FillScreenResolutions(); // Список разрешений экрана берём из Windows

    var SystemDir := ExtractFilePath(ParamStr(0)) + 'System';
    FindIntFiles(SystemDir); // Найти библиотеки рендеринга (точнее прочесть их .int файлы)
    ReadGameSettings();
end;

procedure TfrmMain.LaunchGame();
var
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;
    RunningFile: string;
begin
    RunningFile := RunningPath;

    if TFile.Exists(RunningFile) then
        TFile.Delete(RunningFile);

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));

    var parameters := ' ini="..\2027\System\2027.ini" userini="..\2027\System\2027User.ini" log="..\2027\System\2027.log"';

    if CreateProcess(
    PChar(GamePath), PChar(parameters),nil, nil, False,
    CREATE_NEW_PROCESS_GROUP, nil, nil, StartupInfo,
    ProcessInfo)
    then
    begin
        if chkSingleCore.Checked = True then
            SetProcessAffinityMask(ProcessInfo.hProcess, 1);

        CloseHandle(ProcessInfo.hThread);
        CloseHandle(ProcessInfo.hProcess);
    end
    else
        RaiseLastOSError();

    Application.Terminate();
end;

procedure TfrmMain.lblEnhancedGraphicsClick(Sender: TObject);
begin
    chkEnhancedGraphics.Checked := not chkEnhancedGraphics.Checked ;
end;

procedure TfrmMain.lblRunInWindowClick(Sender: TObject);
begin
    chkRunInWindow.Checked := not chkRunInWindow.Checked;
end;

procedure TfrmMain.lblSingleCoreClick(Sender: TObject);
begin
    chkSingleCore.Checked := not chkSingleCore.Checked;
end;

procedure TfrmMain.ToggleCustomResolutionControls(bShow: Boolean);
begin
    lblResX.Visible := bShow;
    edtResY.Visible := bShow;
    edtResX.Visible := bShow;
end;

procedure TfrmMain.TryToDetectVoiceoverLanguage();
begin
    // Определение директории System
    var SystemDir := ExtractFilePath(ParamStr(0)) + '2027\System\';

    // Получение суммарного размера файлов
    var TotalFileSizeMB := GetTotalFileSizeInMB(AudioFiles, SystemDir);

    if Abs(TotalFileSizeMB - FileSizesRus) <= 2 then
        cmbVoiceoverLang.ItemIndex := 0
    else if Abs(TotalFileSizeMB - FileSizesEng) <= 2 then
        cmbVoiceoverLang.ItemIndex := 1;


    // Отображение суммарного размера файлов
    //ShowMessage(Format('Суммарный размер файлов: %.2f MB', [TotalFileSizeMB]));
end;

end.
