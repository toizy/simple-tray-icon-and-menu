unit TinyTM.Icon;

interface

uses
	Winapi.Windows,
	Winapi.ShellAPI;

type
	PIcon = ^TIcon;

	TIcon = record
	private
		FIconHandle: HICON;
	public
		procedure Init;
		procedure Free;
		//
		procedure LoadFromExe(Filename: string; Index: Integer = 0);
		procedure LoadFromDLL(Filename: string; Index: Integer = 0);
		procedure LoadFromResource(ResourceName: string);
		procedure LoadFromFile(Filename: string);
		//
		property Handle: HICON read FIconHandle;
	end;

implementation

{ TIcon }

procedure TIcon.Init;
begin
	FIconHandle := 0;
end;

procedure TIcon.Free;
begin
	if (FIconHandle <> 0) then
		DestroyIcon(FIconHandle);
end;

procedure TIcon.LoadFromDLL(Filename: string; Index: Integer = 0);
var
	Handle: THandle;
begin
	Handle := LoadLibraryEx(PChar(Filename), 0, LOAD_LIBRARY_AS_DATAFILE);
	FIconHandle := ExtractIcon(Handle, PChar(Filename), Index);
	if (FIconHandle = 0) then;
	FreeLibrary(Handle);
end;

procedure TIcon.LoadFromExe(Filename: string; Index: Integer = 0);
begin
	LoadFromDLL(Filename, Index);
end;

procedure TIcon.LoadFromFile(Filename: string);
begin
	FIconHandle := LoadImage(
		0, 
		PChar(Filename), 
		IMAGE_ICON, 
		GetSystemMetrics(SM_CXSMICON), 
		GetSystemMetrics(SM_CYSMICON), 
		LR_LOADFROMFILE or LR_DEFAULTSIZE or LR_SHARED
		);
end;

procedure TIcon.LoadFromResource(ResourceName: string);
begin
	FIconHandle := LoadIcon(GetModuleHandle(nil), PChar(ResourceName));
end;

end.
