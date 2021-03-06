{ $Id$ }
{
 /***************************************************************************

                  Abstract: Iterface for inspecting the physical properties
                            data on database.
                  Initial Revision : 01/04/2006
                  Authors:
                    - Samuel Jorge Marques Cartaxo
                    - Additional contributors...

 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the OpSim - OPEN SOURCE PROCESS SIMULATOR           *
 *                                                                           *
 *  See the file COPYING.GPL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit PhysicalPropertyExplorerU;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ZDataset,
  ExtCtrls, DBGrids, DBCtrls, DB, Buttons, StdCtrls, ZConnection;

type

  { TPhysicalPropertyExplorer }

  TPhysicalPropertyExplorer = class (TForm)
    btnClose: TButton;
    DbConnectionMaster: TZConnection;
    dbGrid1: TdbGrid;
    DBNavigator1: TDBNavigator;
    dsPureComps: TDatasource;
    Panel1: TPanel;
    Panel2: TPanel;
    tblPureComps: TZTable;
    tblPureCompsANTOINE_VP_A1: TFloatField;
    tblPureCompsANTOINE_VP_B1: TFloatField;
    tblPureCompsANTOINE_VP_C1: TFloatField;
    tblPureCompsCOMPONENT1: TStringField;
    tblPureCompsCP_A1: TFloatField;
    tblPureCompsCP_B1: TFloatField;
    tblPureCompsCP_C1: TFloatField;
    tblPureCompsCP_D1: TFloatField;
    tblPureCompsDELGF1: TFloatField;
    tblPureCompsDELHG1: TFloatField;
    tblPureCompsDIPM1: TFloatField;
    tblPureCompsHARLACHER_VP_A1: TFloatField;
    tblPureCompsHARLACHER_VP_B1: TFloatField;
    tblPureCompsHARLACHER_VP_C1: TFloatField;
    tblPureCompsHARLACHER_VP_D1: TFloatField;
    tblPureCompsHV1: TFloatField;
    tblPureCompsLIQDEN1: TFloatField;
    tblPureCompsMOLE_WT1: TFloatField;
    tblPureCompsNUMBER1: TLongintField;
    tblPureCompsOMEGA1: TFloatField;
    tblPureCompsPC1: TFloatField;
    tblPureCompsTB1: TFloatField;
    tblPureCompsTC1: TFloatField;
    tblPureCompsTDEN1: TFloatField;
    tblPureCompsTFP1: TFloatField;
    tblPureCompsTMN1: TFloatField;
    tblPureCompsTMX1: TFloatField;
    tblPureCompsVC1: TFloatField;
    tblPureCompsVISC_LIQ_B1: TFloatField;
    tblPureCompsVISC_LIQ_C1: TFloatField;
    tblPureCompsZC1: TFloatField;
    procedure btnCloseClick(Sender: TObject);
    procedure DbConnectionMasterBeforeConnect(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  end;
  
var
  PhysicalPropertyExplorer: TPhysicalPropertyExplorer;

implementation

uses
  DMBaseU;

{ TPhysicalPropertyExplorer }


{
************************** TPhysicalPropertyExplorer ***************************
}
procedure TPhysicalPropertyExplorer.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TPhysicalPropertyExplorer.DbConnectionMasterBeforeConnect(Sender: 
        TObject);
begin
  
end;

procedure TPhysicalPropertyExplorer.FormCreate(Sender: TObject);
begin
  with tblPureComps do begin
    Connection := DMBase.DbConnectionMaster;
    DMBase.Connect;
    Open;
  end;//with
end;

initialization
  {$I PhysicalPropertyExplorerU.lrs}

end.

