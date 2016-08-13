unit UnitMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, UnitTagReader, Generics.Collections, UnitTagTypes, MediaInfoDll,
  Vcl.Mask, Vcl.ImgList, JvComponentBase, JvDragDrop, Vcl.Buttons, Vcl.Menus,
  System.ImageList;

type
  TFileItem = class
    FullPath, TagType, Title, Artist, Album, AlbumArtist, Genre, Comment, Track, Composer, Year: string;
  end;

  TFileItems = TList<TFileItem>;

type
  TMainForm = class(TForm)
    PageControl1: TPageControl;
    sTabSheet1: TTabSheet;
    sPanel1: TPanel;
    ApplyBtn: TButton;
    ReloadBtn: TButton;
    FileList: TListView;
    TitleEdit: TEdit;
    ArtistEdit: TEdit;
    AlbumArtistEdit: TEdit;
    AlbumEdit: TEdit;
    DateEdit: TEdit;
    TrackEdit: TEdit;
    ComposerEdit: TEdit;
    CommentEdit: TEdit;
    GenreList: TComboBox;
    JvDragDrop1: TJvDragDrop;
    sStatusBar1: TStatusBar;
    TopPanel: TPanel;
    AddFileBtn: TBitBtn;
    RemoveSelectedBtn: TBitBtn;
    RemoveAllBtn: TBitBtn;
    AboutBtn: TBitBtn;
    MainMenu1: TMainMenu;
    F1: TMenuItem;
    T1: TMenuItem;
    A1: TMenuItem;
    R1: TMenuItem;
    R2: TMenuItem;
    S1: TMenuItem;
    R3: TMenuItem;
    A2: TMenuItem;
    ImageList1: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure FileListData(Sender: TObject; Item: TListItem);
    procedure FileListClick(Sender: TObject);
    procedure JvDragDrop1Drop(Sender: TObject; Pos: TPoint; Value: TStrings);
    procedure TitleEditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FTagReader: TTagReader;
    FEditedListItem: TListItem;
    FTags: TGeneralTagList;
    FDisplayTags: TGeneralTagList;
    FAppData: string;
    FSettingsFile: TStringList;
    FFileItems: TFileItems;
    procedure EditChange(Sender: TObject);
    procedure GetFileInfoForDisplay(const FileName: string);
  public
    { Public declarations }
    procedure GetFileInfo(const FileIndex: integer);
    // protected
    // procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.ApplyBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to FTags.Count - 1 do
  begin
    if FTags[i].Edited then
    begin
      ShowMessage(FTags[i].Tag + '/' + FTags[i].Value);
      Break;
    end;
  end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  Self.Close;
end;

// procedure TMainForm.CreateParams(var Params: TCreateParams);
// begin
// inherited;
//
// Params.ExStyle := Params.ExStyle and not WS_EX_APPWINDOW;
// Params.WndParent := Application.Handle;
// end;

procedure TMainForm.EditChange(Sender: TObject);
begin
  ApplyBtn.Enabled := True;
  FTags[TEdit(Sender).Tag].Edited := True;
end;

procedure TMainForm.FileListClick(Sender: TObject);
begin
  if FileList.ItemIndex > -1 then
  begin
    GetFileInfo(FileList.ItemIndex);
  end;
end;

procedure TMainForm.FileListData(Sender: TObject; Item: TListItem);
begin
  if Item.Index < FFileItems.Count then
  begin
    Item.Caption := ExtractFileName(FFileItems[Item.Index].FullPath);
    Item.SubItems.Add(FFileItems[Item.Index].TagType);
    Item.SubItems.Add(FFileItems[Item.Index].Title);
    Item.SubItems.Add(FFileItems[Item.Index].Artist);
    Item.SubItems.Add(FFileItems[Item.Index].AlbumArtist);
    Item.SubItems.Add(FFileItems[Item.Index].Album);
    Item.SubItems.Add(FFileItems[Item.Index].Genre);
    Item.SubItems.Add(FFileItems[Item.Index].Track);
    Item.SubItems.Add(FFileItems[Item.Index].Comment);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
  LTagFilePath: string;
  LTagFile: TStringList;
begin
  FTagReader := TTagReader.Create;
  FTags := TGeneralTagList.Create;
  FDisplayTags := TGeneralTagList.Create;
  FSettingsFile := TStringList.Create;
  if not MediaInfoDLL_Load(ExtractFileDir(Application.ExeName) + '\mediainfo.dll') then
  begin
    Application.MessageBox('Couldn''t load mediainfo.dll library.', 'Fatal Error', MB_ICONERROR);
    Application.Terminate;
  end;
  FFileItems := TFileItems.Create;
  LTagFilePath := ParamStr(1);
  if FileExists(LTagFilePath) then
  begin
    LTagFile := TStringList.Create;
    try
      LTagFile.LoadFromFile(LTagFilePath, TEncoding.UTF8);
      for I := 0 to LTagFile.Count - 1 do
      begin
        GetFileInfoForDisplay(LTagFile[i]);
        FileList.Items.Count := FFileItems.Count;
        GetFileInfo(FFileItems.Count - 1);
      end;
    finally
      LTagFile.Free;
    end;
    DeleteFile(LTagFilePath);
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  i: integer;
begin
  FTagReader.Free;
  for I := 0 to FTags.Count - 1 do
  begin
    FTags[i].Free;
  end;
  FTags.Free;
  for I := 0 to FDisplayTags.Count - 1 do
  begin
    FDisplayTags[i].Free;
  end;
  FDisplayTags.Free;
  for I := 0 to FFileItems.Count - 1 do
  begin
    FFileItems[i].Free;
  end;
  FFileItems.Free;

  FSettingsFile.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  FileListClick(Self);
end;

procedure TMainForm.GetFileInfo(const FileIndex: integer);
begin
  TitleEdit.Text := '';
  ArtistEdit.Text := '';
  AlbumArtistEdit.Text := '';
  AlbumEdit.Text := '';
  TrackEdit.Text := '';
  DateEdit.Text := '';
  GenreList.Text := '';
  ComposerEdit.Text := '';
  CommentEdit.Text := '';
  with FFileItems[FileIndex] do
  begin
    TitleEdit.Text := Title;
    ArtistEdit.Text := Artist;
    AlbumArtistEdit.Text := AlbumArtist;
    AlbumEdit.Text := Album;
    TrackEdit.Text := Track;
    DateEdit.Text := '';
    GenreList.Text := Genre;
    ComposerEdit.Text := Composer;
    CommentEdit.Text := Comment;
  end;
  ApplyBtn.Enabled := False;
end;

procedure TMainForm.GetFileInfoForDisplay(const FileName: string);
var
  i: Integer;
  LFileItem: TFileItem;
  LTagDisplayName: string;
  LTags: TPlayItem;
begin
  if (FileExists(FileName)) then
  begin
    if not FTagReader.IsBusy then
    begin
      LTags := TPlayItem.Create;
      try
        LTags := FTagReader.ReadTagsForTagEditorList(FileName);
        LFileItem := TFileItem.Create;

        LFileItem.FullPath := FileName;
        LFileItem.Title := LTags.Title;
        LFileItem.Artist := LTags.Artist;
        LFileItem.Album := LTags.Album;
        LFileItem.AlbumArtist := LTags.AlbumArtist;
        LFileItem.Genre := LTags.Genre;
        LFileItem.Comment := LTags.Comment;
        LFileItem.Track := LTags.Track;
        LFileItem.Composer := LTags.Composer;
        LFileItem.Year := LTags.Date;

        FFileItems.Add(LFileItem);
      finally
        LTags.Free;
      end;
    end;
  end;
end;

procedure TMainForm.JvDragDrop1Drop(Sender: TObject; Pos: TPoint; Value: TStrings);
var
  I: Integer;
begin
  for I := 0 to Value.Count - 1 do
  begin
    GetFileInfoForDisplay(Value[i]);
  end;
  FileList.Items.Count := FFileItems.Count;
  GetFileInfo(0);
end;

procedure TMainForm.TitleEditChange(Sender: TObject);
begin
  ApplyBtn.Enabled := True;
end;

end.

