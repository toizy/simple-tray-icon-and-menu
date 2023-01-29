unit TinyTM;

interface

uses
	Winapi.Windows,
	Winapi.Messages,
	Winapi.ShellAPI,
	TinyTM.Menu,
	TinyTM.Icon;

const
	USER_UNIQUE_ID = $FFFF;

type
	{ TODO : Tray icon manager }

	TTrayIconFunc = procedure;
	TTrayMenuFunc = procedure(MI: TMenuItem);

	{ TConsoleTrayIcon }

	TConsoleTrayIcon = record
	private
		type
		TWindow = record
			Classname: string;
			Handle: HWND;
			WinClass: TWndClass;
			NID: TNotifyIconData;
		end;
	private
		FActive: Boolean;
		FWindow: TWindow;
		FInst: HMODULE;
		FIcon: TIcon;
		FMenu: PMenuItem;
		FList: array of Pointer;
		FOnClick: TTrayMenuFunc;
		FThreadID: TThreadID;
		FThreadHandle: THandle;
		FToolTip: string;
		FOnDblClick: TTrayIconFunc;
		//
		procedure DestroyIcon;
		function GetItems: PMenuItem;
		function GetOnClick: TTrayMenuFunc;
		procedure SetOnClick(const Value: TTrayMenuFunc);
		procedure OnItemAdd(MenuItem: Pointer);
		procedure CreateIcon;
		function GetToolTip: string;
		procedure SetToolTip(const Value: string);
		function GetIcon: PIcon;
		function GetOnDblClick: TTrayIconFunc;
		procedure SetOnDblClick(const Value: TTrayIconFunc);
	public
		procedure Init;
		procedure Free;
		//
		procedure SetActive(Active: Boolean);
		procedure ShowMenu;
		//
		property Menu: PMenuItem read GetItems;
		property OnClick: TTrayMenuFunc read GetOnClick write SetOnClick;
		property ToolTip: string read GetToolTip write SetToolTip;
		property Icon: PIcon read GetIcon;
		property OnDblClick: TTrayIconFunc read GetOnDblClick write SetOnDblClick;
	end;

implementation

type
	PConsoleTrayIcon = ^TConsoleTrayIcon;

var
	WindowList: array of PConsoleTrayIcon;

function FindTrayIconInArray(Handle: HWND): PConsoleTrayIcon;
var
	i: Integer;
begin
	Result := nil;
	for i := Low(WindowList) to High(WindowList) do
	begin
		if (WindowList[i]^.FWindow.Handle = Handle) then
		begin
			Result := WindowList[i];
			Break;
		end;
	end;
end;

procedure AddTrayIconToArray(TI: PConsoleTrayIcon);
begin
	if (FindTrayIconInArray(TI.FWindow.Handle) = nil) then
	begin
		SetLength(WindowList, Length(WindowList) + 1);
		WindowList[High(WindowList)] := TI;
	end;
end;

procedure DeleteTrayIconFromArray(TI: PConsoleTrayIcon);
var
	i, L, Index: Integer;
begin
	// Delete Self from internal array
	Index := -1;
	for i := Low(WindowList) to High(WindowList) do
		if (WindowList[i] = TI) then
		begin
			Index := i;
			Break;
		end;

	if (Index > -1) then
	begin
		L := Length(WindowList);
		for i := Index + 1 to L - 1 do
			WindowList[i - 1] := WindowList[i];
		SetLength(WindowList, L - 1);
	end;
end;

function WindowProc(HWND: HWND; MSG: UINT; wParam: wParam; lParam: lParam): LRESULT; stdcall;
var
	i: Integer;
	TI: PConsoleTrayIcon;
	MI: TMenuItem;
begin
	Result := DefWindowProc(HWND, MSG, wParam, lParam);
	case MSG of
		WM_DESTROY:
			begin
				MessageBox(0, '', '', MB_OK);
				PostQuitMessage(0);
			end;
		WM_USER:
			begin
				case lParam of
					WM_RBUTTONUP:
						begin
							TI := FindTrayIconInArray(HWND);
							if (TI <> nil) then
								TI.ShowMenu;
						end;
					WM_LBUTTONUP:
						begin

						end;
					WM_LBUTTONDBLCLK:
						begin
							TI := FindTrayIconInArray(HWND);
							if (TI <> nil) then
								if (Assigned(TI.FOnDblClick)) then
									TI.OnDblClick;
						end;
				end;
			end;
		WM_COMMAND:
			begin
				// Click on item, not hotkey (1)
				if (lParam = 0) then
				begin
					TI := FindTrayIconInArray(HWND);
					if (TI <> nil) then
					begin
						if (Assigned(TI.OnClick)) then
						begin
							for i := Low(TI.FList) to High(TI.FList) do
							begin
								MI := TMenuItem(TI.FList[i]^);
								if (MI.UniqueID = Integer(wParam)) then
								begin
									TI.OnClick(MI);
									if (MI.IsRadioItem) then
										MI.CheckRadio;
									Break;
								end;
							end;
						end;
					end;
				end;
			end;
	end;
end;

function ThreadFunc(Parameter: Pointer): Integer;
var
	TI: PConsoleTrayIcon;
	MSG: TMsg;
begin
	TI := PConsoleTrayIcon(Parameter);
	TI.CreateIcon();
	while TI.FActive do
		if GetMessage(MSG, 0, 0, 0) then
		begin
			TranslateMessage(MSG);
			DispatchMessage(MSG);
		end;
	TI.DestroyIcon;
	Result := 0;
end;

{ TConsoleTrayIcon }

function TConsoleTrayIcon.GetIcon: PIcon;
begin
	Result := @FIcon;
end;

procedure TConsoleTrayIcon.Init;
begin
	FIcon.Init;
	FActive := False;
	FInst := GetModuleHandle(nil);
	New(FMenu);
	FMenu.Init;
	FMenu.OnItemAdd := OnItemAdd;
end;

function TConsoleTrayIcon.GetItems: PMenuItem;
begin
	Result := FMenu;
end;

function TConsoleTrayIcon.GetOnClick: TTrayMenuFunc;
begin
	Result := FOnClick;
end;

function TConsoleTrayIcon.GetOnDblClick: TTrayIconFunc;
begin
	Result := FOnDblClick;
end;

function TConsoleTrayIcon.GetToolTip: string;
begin
	Result := FToolTip;
end;

procedure TConsoleTrayIcon.OnItemAdd(MenuItem: Pointer);
begin
	SetLength(FList, Length(FList) + 1);
	FList[High(FList)] := MenuItem;
end;

procedure TConsoleTrayIcon.SetActive(Active: Boolean);
begin
	if (Active) then
	begin
		if (not FActive) then
			FThreadHandle := BeginThread(nil, 0, @ThreadFunc, @Self, 0, FThreadID);
	end
	else
	begin
		if (FActive) then
		begin
			WaitForSingleObject(FThreadHandle, 100);
			CloseHandle(FThreadHandle);
			FActive := False;
		end;
	end;
end;

procedure TConsoleTrayIcon.SetOnClick(const Value: TTrayMenuFunc);
begin
	FOnClick := Value;
end;

procedure TConsoleTrayIcon.SetOnDblClick(const Value: TTrayIconFunc);
begin
	FOnDblClick := Value;
end;

procedure TConsoleTrayIcon.SetToolTip(const Value: string);
begin
	FToolTip := Value;
end;

procedure TConsoleTrayIcon.ShowMenu;
var
	P: TPoint;
begin
	// SetForegroundWindow is necessary to hide the menu when clicking outside the menu area
	SetForegroundWindow(FWindow.Handle);
	GetCursorPos(P);
	TrackPopupMenu(FMenu.Handle, 0, P.X, P.Y, 0, FWindow.Handle, nil);
	PostMessage(FWindow.Handle, WM_NULL, 0, 0);
end;

procedure TConsoleTrayIcon.CreateIcon;

	function GenerateClassname: string;
	const
		CharSequence: String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
		Len: Integer = 16;
	var
		i, SequenceLength: Integer;
	begin
		SequenceLength := Length(CharSequence);
		SetLength(Result, Len);
		Randomize;
		for i := Low(Result) to High(Result) do
			Result[i] := CharSequence[Random(SequenceLength - 1) + 1];
	end;

begin
	DestroyIcon;

	// Create a window class
	FWindow.Classname := GenerateClassname;

	FWindow.WinClass.lpfnWndProc := @WindowProc;
	FWindow.WinClass.hInstance := FInst;

	FWindow.WinClass.lpszClassName := PChar(FWindow.Classname);

	RegisterClass(FWindow.WinClass);

	// Create a window
	FWindow.Handle := CreateWindow(
		PChar(FWindow.Classname),
		PChar(FWindow.Classname),
		WS_POPUP or WS_CAPTION, -MAXWORD, 0, 0, 0, 0, 0, FInst, nil);

	AddTrayIconToArray(@Self);

	// Register shell notifiation data
	FWindow.NID.uID := 0;
	FWindow.NID.Wnd := FWindow.Handle;
	FWindow.NID.uCallbackMessage := WM_USER;
	FWindow.NID.HICON := Icon.Handle;
	FWindow.NID.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
	FWindow.NID.cbSize := SizeOf(FWindow.NID);
	lstrcpy(FWindow.NID.szTip, PChar(FToolTip));

	Shell_NotifyIcon(NIM_ADD, @FWindow.NID);

	FActive := True;
end;

procedure TConsoleTrayIcon.DestroyIcon;
begin
	if (FActive) then
	begin
		DeleteTrayIconFromArray(@Self);

		// Clear menu, delete tray icon, and unregister window
		FMenu.Clear;
		Shell_NotifyIcon(NIM_DELETE, @FWindow.NID);
		UnRegisterClass(PChar(FWindow.Classname), FInst);
	end;
	FActive := False;
end;

procedure TConsoleTrayIcon.Free;
begin
	DestroyIcon;
	FIcon.Free;
	FMenu.Free;
	Dispose(FMenu);
end;

end.
