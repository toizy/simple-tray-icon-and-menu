program Demo;

{$APPTYPE CONSOLE}

uses
	Winapi.Windows,
	Winapi.Messages,
	TinyTM in 'TinyTM.pas',
	TinyTM.Menu in 'TinyTM.Menu.pas',
	TinyTM.Icon in 'TinyTM.Icon.pas',
	TinyTM.Utils in 'TinyTM.Utils.pas';

{$IFNDEF DEBUG}
{$IFOPT D-}{$WEAKLINKRTTI ON}{$ENDIF}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}
{$ENDIF}


const
	ID_SHUTDOWN = USER_UNIQUE_ID + 1;

var
	TI: TConsoleTrayIcon;

function FNHandlerRoutine(CtrlType: NativeUInt): BOOL; stdcall;
begin
	TI.Free;
	Result := True;
end;

procedure OnDoubleClick;
begin
	MessageBox(0, 'DblClicked!', '', MB_OK or MB_ICONINFORMATION);
end;

procedure OnMenuClick(MI: TMenuItem);
begin
	case MI.UniqueID of
		ID_SHUTDOWN:
			begin
				TI.Free;
				Halt;
			end;
	else
		MI.ToggleCheck;
	end
end;

begin
{$IFDEF DEBUG}
	ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
	SetConsoleCtrlHandler(@FNHandlerRoutine, True);

	TI.Init;
	TI.OnClick := OnMenuClick;
	TI.OnDblClick := OnDoubleClick;
	TI.ToolTip := 'MiniTeleporter Helper';
	// TI.Icon.LoadFromResource('Icon_1');
	// TI.Icon.LoadFromExe('calc.exe');
	TI.Icon.LoadFromFile('OneDrive.ico');
	SendMessage(GetConsoleWindow, WM_SETICON, ICON_SMALL, NativeInt(TI.Icon.Handle));
	SendMessage(GetConsoleWindow, WM_SETICON, ICON_BIG, NativeInt(TI.Icon.Handle));
	TI.SetActive(True);

	TI.Menu.Add('*1', 111);
	TI.Menu.Add('*2', 222);
	TI.Menu.Add('**3', 333);
	TI.Menu.Add('-', 0);
	TI.Menu.Add('Exit', ID_SHUTDOWN);

	Readln;

	TI.Free;

end.
