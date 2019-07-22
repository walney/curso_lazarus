unit upropdv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, MaskEdit,
  EditBtn, StdCtrls, Buttons, DBCtrls, DBGrids, rxcurredit, ACBrEnterTab,
  BufDataset, db;

type

  { Tfrmpropdv }

  Tfrmpropdv = class(TForm)
    ACBrEnterTab1: TACBrEnterTab;
    btnListar: TBitBtn;
    btnCancelar: TBitBtn;
    btnFechar: TBitBtn;
    btnGravar: TBitBtn;
    bufPagamento: TBufDataset;
    bufTemp: TBufDataset;
    dtsBufPagamento: TDataSource;
    edtValor: TCurrencyEdit;
    edtQtde: TCurrencyEdit;
    dtsbufTemp: TDataSource;
    grdProdutos: TDBGrid;
    imgFotoProduto: TImage;
    edtCodigo: TMaskEdit;
    edtDescricao: TMaskEdit;
    lblUsuario: TLabel;
    lblTotalVenda: TLabel;
    lblCodigoGTIN: TLabel;
    lblDescricao: TLabel;
    lblProduto: TLabel;
    lblQtde: TLabel;
    edtTotalVenda: TMaskEdit;
    Panel1: TPanel;
    pnlBotoes: TPanel;
    pnlFotoProduto: TPanel;
    procedure btnCancelarClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
    procedure edtQtdeExit(Sender: TObject);
    procedure edtCodigoExit(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure grdProdutosKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    UltimoProdutoId:String;
    procedure ConfigurarCampos;
    function GravarFormaPagamentoBufDataSet: Boolean;
    procedure SetFocusPadrao;
    procedure SelecionarProduto(Gtin:String);
    function Sequenciar:Integer;
    procedure GravarProdutoBufTemp;
    procedure LimparCampos(todos:boolean=false);
    procedure LimparBufDataSet;
  public

  end;

var
  frmpropdv: Tfrmpropdv;

implementation

{$R *.lfm}

uses uPrincipal, cCadProduto, uConexao, uUtils, cpdvvenda, cpdvvendaproduto,
     upropdv_pagamento;

{ Tfrmpropdv }

procedure Tfrmpropdv.SetFocusPadrao;
begin
  edtCodigo.SetFocus;
end;

procedure Tfrmpropdv.SelecionarProduto(Gtin: String);
var oProduto:TProduto;
begin
  try
    oProduto:=TProduto.Create(DtmPrincipal.ConDataBase);
    oProduto.SelecionarGTIN(Gtin);

    if (oProduto.gtin <> EmptyStr) then begin
       UltimoProdutoId:=oProduto.produtoId;
       edtdescricao.Text:=oProduto.descricao;
       edtValor.value:=oProduto.valorVenda;
       imgFotoProduto.Picture.Assign(oProduto.foto);
       edtQtde.Text:='1';
    end;

  finally
    if Assigned(oProduto) then
      FreeAndNil(oProduto);
  end;
end;

function Tfrmpropdv.Sequenciar: Integer;
begin
   if bufTemp.IsEmpty then begin
     Result:=1
   end
   else begin
     bufTemp.Last;
     result:=bufTemp.FieldByName('Item').AsInteger+1;
   end;
end;

procedure Tfrmpropdv.GravarProdutoBufTemp;
var iProximo:Integer;
    dValorTotal:Double;
begin
   if (edtValor.value<=0) or (edtQtde.value<=0) or (edtCodigo.Text=EmptyStr) then begin
      Exit;
   end;

   if edtQtde.Value=0 then
     edtQtde.Value:=1;

   iProximo:=Sequenciar;

   bufTemp.Append;
   bufTemp.FieldByName('Item').AsInteger:=iProximo;
   bufTemp.FieldByName('produtoid').AsString:=UltimoProdutoId;
   bufTemp.FieldByName('codigogtin').AsString:=edtCodigo.Text;
   bufTemp.FieldByName('descricao').AsString:=edtdescricao.Text;
   bufTemp.FieldByName('quantidade').AsFloat:=StrToFloat(edtQtde.Text);
   bufTemp.FieldByName('valorUnitario').AsFloat:=edtValor.Value;
   bufTemp.FieldByName('valorTotal').AsFloat:= bufTemp.FieldByName('quantidade').AsFloat * bufTemp.FieldByName('valorUnitario').AsFloat;
   bufTemp.Post;

   LimparCampos;

   try
     bufTemp.DisableControls;
     bufTemp.First;
     dValorTotal:=0;
     while not bufTemp.EOF do begin
       dValorTotal:=dValorTotal+bufTemp.FieldByName('valorTotal').AsFloat;
       bufTemp.Next;
     end;
   finally
     bufTemp.Last;
     bufTemp.EnableControls;
     edtTotalVenda.Text:=FormatFloat('#0.00',dValorTotal);
   end;

end;

procedure Tfrmpropdv.LimparCampos(todos: boolean=false);
begin
  edtCodigo.Text:=EmptyStr;
  edtdescricao.Text:=EmptyStr;
  edtQtde.Value:=1;
  edtValor.Value:=0;
  imgFotoProduto.Picture.Assign(nil);
  if todos then
    edtTotalVenda.Text:='0.00';
end;

procedure Tfrmpropdv.LimparBufDataSet;
begin
  bufTemp.First;
  while not bufTemp.Eof do
    bufTemp.Delete;

  bufPagamento.First;
  while not bufPagamento.Eof do
    bufPagamento.Delete;
end;

procedure Tfrmpropdv.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure Tfrmpropdv.btnCancelarClick(Sender: TObject);
begin
  LimparBufDataSet;
  LimparCampos(true);
end;


function Tfrmpropdv.GravarFormaPagamentoBufDataSet:Boolean;
begin
  try
    Result := false;
    frmpropdvpagamento:=Tfrmpropdvpagamento.Create(Self);
    frmpropdvpagamento.edtValorTotal.Value:=StrToFloat(edtTotalVenda.Text);
    frmpropdvpagamento.ShowModal;

    if frmpropdvpagamento.bCancelou then
       Exit;

    bufPagamento.Append;
    bufPagamento.FieldByName('item').AsInteger:=1;
    bufPagamento.FieldByName('codigoMeioPagamento').AsString:=frmpropdvpagamento.sCodigoMeioPagamento;
    case StrToInt(frmpropdvpagamento.sCodigoMeioPagamento) of
      1: bufPagamento.FieldByName('descricaoMeioPagamento').AsString := 'Dinheiro';
      2: bufPagamento.FieldByName('descricaoMeioPagamento').AsString := 'Cheque';
      3: bufPagamento.FieldByName('descricaoMeioPagamento').AsString := 'Cartão de Crédito';
      4: bufPagamento.FieldByName('descricaoMeioPagamento').AsString := 'Cartão de Débito';
      5: bufPagamento.FieldByName('descricaoMeioPagamento').AsString := 'Crédito Loja';
     99: bufPagamento.FieldByName('descricaoMeioPagamento').AsString := 'Outros';
    end;

    if (bufPagamento.FieldByName('codigoMeioPagamento').AsString='03') or
       (bufPagamento.FieldByName('codigoMeioPagamento').AsString='04') then begin
        bufPagamento.FieldByName('codigoCartao').AsString := frmpropdvpagamento.sCodigoCartao;

        case StrToInt(frmpropdvpagamento.sCodigoCartao) of
            1: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Visa';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '01027058000191';
            end;
            2: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'MasterCard';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '01425787000104';
            end;
            3: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'American Express';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '60419645000195';
            end;
            4: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Sorocred';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '60114865000100';
            end;
            5: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Diners Club';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '54419627000100';
            end;
            6: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Elo';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '09227084000175';
            end;
            7: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Hipercard';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '03012230000169';
            end;
            8: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Aura';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '17251707000173';
            end;
            9: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Cabal';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '03766873000106';
            end;
           99: begin
               bufPagamento.FieldByName('operadoraCartao').AsString := 'Outros';
               bufPagamento.FieldByName('cnpjOperadoraCartao').AsString := '';
           end;
        end
    end;
    bufPagamento.FieldByName('valorPago').AsFloat:=frmpropdvpagamento.edtValorPago.Value;
    bufPagamento.FieldByName('valorTroco').AsFloat:=frmpropdvpagamento.edtTroco.Value;
    bufPagamento.Post;
    Result:=true;
  finally
    if Assigned(frmpropdvpagamento) then
       frmpropdvpagamento.Release;
  end;

end;

procedure Tfrmpropdv.btnGravarClick(Sender: TObject);
var oVenda:TPdvVenda;
    oVendaProduto:TPdvVendaProduto;
begin

  if bufTemp.IsEmpty then
     exit;

  if not GravarFormaPagamentoBufDataSet then
     exit;

  try
    Screen.Cursor:=crSQLWait;
    oVenda:=TPdvVenda.Create(dtmPrincipal.ConDataBase);
    oVenda.usuarioId:=oUsuarioLogado.codigo;
    oVenda.data:=Date;
    oVenda.hora:=Time;
    oVenda.valorTotalVenda:=StrToFloat(edtTotalVenda.Text);

    if (oVenda.Inserir) then begin
      try
        bufTemp.DisableControls;
        bufTemp.First;
        while not bufTemp.EOF do begin

          try
            oVendaProduto:=TPdvVendaProduto.Create(dtmPrincipal.ConDataBase);
            oVendaProduto.pdvVendaId:=oVenda.pdvVendaId;
            oVendaProduto.item:=bufTemp.FieldByName('item').AsInteger;
            oVendaProduto.produtoId:=bufTemp.FieldByName('produtoid').AsString;
            oVendaProduto.gtin:=bufTemp.FieldByName('codigogtin').AsString;
            oVendaProduto.descricaoProduto:=bufTemp.FieldByName('descricao').AsString;
            oVendaProduto.qtde:=bufTemp.FieldByName('quantidade').AsFloat;
            oVendaProduto.valorUnitario:=bufTemp.FieldByName('valorUnitario').AsFloat;
            oVendaProduto.valorTotalProduto:=bufTemp.FieldByName('valorTotal').AsFloat;
            if oVendaProduto.Inserir then begin
               TProduto.BaixaNoEstoque(bufTemp.FieldByName('produtoid').AsString,
                                       bufTemp.FieldByName('quantidade').AsFloat,
                                       dtmPrincipal.ConDataBase);
            end;


          finally
            if Assigned(oVendaProduto) then
               FreeAndNil(oVendaProduto);
          end;

          bufTemp.Next;
        end;
      finally
        bufTemp.EnableControls;
      end;
    end;
  finally
    Screen.Cursor:=crDefault;
    LimparBufDataSet;
    LimparCampos(true);
  end;
end;

procedure Tfrmpropdv.edtQtdeExit(Sender: TObject);
begin
  GravarProdutoBufTemp;
  SetFocusPadrao;
end;

procedure Tfrmpropdv.edtCodigoExit(Sender: TObject);
begin
  SelecionarProduto(TMaskEdit(Sender).Text);
end;

procedure Tfrmpropdv.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  bufTemp.Close;
end;

procedure Tfrmpropdv.FormCreate(Sender: TObject);
begin
  bufTemp.FieldDefs.Add('item',ftInteger,0);
  bufTemp.FieldDefs.Add('codigogtin',ftString,14);
  bufTemp.FieldDefs.Add('descricao',ftString,50);
  bufTemp.FieldDefs.Add('quantidade',ftFloat,0);
  bufTemp.FieldDefs.Add('valorUnitario',ftFloat,0);
  bufTemp.FieldDefs.Add('valorTotal',ftFloat);
  bufTemp.FieldDefs.Add('produtoId', ftString, 36);

  bufTemp.CreateDataset;
  dtsbufTemp.DataSet:=bufTemp;
  grdProdutos.DataSource:=dtsbufTemp;

  bufPagamento.FieldDefs.Add('item',ftInteger,0);
  bufPagamento.FieldDefs.Add('codigoMeioPagamento',ftString,2);
  bufPagamento.FieldDefs.Add('descricaoMeioPagamento',ftString,36);
  bufPagamento.FieldDefs.Add('codigoCartao',ftString,2);
  bufPagamento.FieldDefs.Add('operadoraCartao',ftString,30);
  bufPagamento.FieldDefs.Add('cnpjOperadoraCartao',ftString,20);
  bufPagamento.FieldDefs.Add('valorPago',ftFloat,0);
  bufPagamento.FieldDefs.Add('valorTroco',ftFloat,0);
  bufPagamento.CreateDataset;
  dtsBufPagamento.DataSet:=bufPagamento;

  ACBrEnterTab1.EnterAsTab:=true;
  ConfigurarCampos;
end;

procedure Tfrmpropdv.FormShow(Sender: TObject);
begin
  SetFocusPadrao;
  lblUsuario.Caption:=oUsuarioLogado.nome;
end;

procedure Tfrmpropdv.ConfigurarCampos;
begin
  bufTemp.Fields[0].DisplayLabel:='Item';
  bufTemp.Fields[1].DisplayLabel:='Código GTIN';
  bufTemp.Fields[2].DisplayLabel:='Descrição';
  bufTemp.Fields[3].DisplayLabel:='Quantidade';
  bufTemp.Fields[4].DisplayLabel:='Valor Unitário';
  bufTemp.Fields[5].DisplayLabel:='Valor Produto';

  grdProdutos.Columns.Add();
  grdProdutos.Columns[0].FieldName:='item';
  grdProdutos.Columns[0].Width:=100;

  grdProdutos.Columns.Add();
  grdProdutos.Columns[1].FieldName:='codigogtin';
  grdProdutos.Columns[1].Width:=250;

  grdProdutos.Columns.Add();
  grdProdutos.Columns[2].FieldName:='descricao';
  grdProdutos.Columns[2].Width:=400;

  grdProdutos.Columns.Add();
  grdProdutos.Columns[3].FieldName:='quantidade';
  grdProdutos.Columns[3].Width:=200;

  grdProdutos.Columns.Add();
  grdProdutos.Columns[4].FieldName:='valorUnitario';
  grdProdutos.Columns[4].Width:=150;

  grdProdutos.Columns.Add();
  grdProdutos.Columns[5].FieldName:='valorTotal';
  grdProdutos.Columns[5].Width:=200;

end;

procedure Tfrmpropdv.grdProdutosKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //Bloqueia o CTRL + DEL
   if (Shift = [ssCtrl]) and (Key = 46) then
      Key := 0;
end;

end.

