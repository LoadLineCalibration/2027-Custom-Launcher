unit Launch2027.Utils;

interface

uses
  Launch2027.Classes, Math, System.SysUtils, system.IOUtils;

function CalculateFov(Resolution: TScreenResolution): Double;
function GetTotalFileSizeInMB(const Files: array of string; const Directory: string): Double;


implementation

function DegreeToRadian(Angle: Double): Double;
begin
    Result := Angle * (Pi / 180.0);
end;

function RadianToDegree(Angle: Double): Double;
begin
    Result := Angle * (180.0 / Pi);
end;

function CalculateFov(Resolution: TScreenResolution): Double;
var
    AspectRatio: Double;
    Tan75Degrees: Double;
begin
    AspectRatio := (Resolution.Width / Resolution.Height) / (4.0 / 3.0);
    Tan75Degrees := Tan(DegreeToRadian(75) / 2);
    Result := RadianToDegree(2 * Arctan(AspectRatio * Tan75Degrees));
end;

function GetTotalFileSizeInMB(const Files: array of string; const Directory: string): Double;
var
    FileName: string;
    FileSize: Int64;
    TotalSize: Int64;
begin
    TotalSize := 0;
    for var i := Low(Files) to High(Files) do
    begin
        FileName := TPath.Combine(Directory, Files[i] + '.u');
        if FileExists(FileName) then
        begin
            FileSize := TFile.GetSize(FileName);
            TotalSize := TotalSize + FileSize;
        end;
    end;

    Result := TotalSize / (1024 * 1024); // Конвертация байтов в мегабайты
end;

end.
