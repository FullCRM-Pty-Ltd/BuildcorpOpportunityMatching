import { LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import Id from '@salesforce/user/Id';
import getUserBusinessUnit from '@salesforce/apex/opportunityScoringRecalcController.getUserBusinessUnit'
import updateWeightings from '@salesforce/apex/opportunityScoringRecalcController.updateWeightings'
import getFieldStringListFromFieldSet from '@salesforce/apex/opportunityScoringRecalcController.getFieldStringListFromFieldSet'
import CalculateOpportunityScoreWeighted from '@salesforce/apex/OpportunityScoringCalculator.CalculateOpportunityScoreWeighted'
import getMarketOptions from '@salesforce/apex/opportunityScoringRecalcController.getMarketOptions'
import getNumberOfOppsToUpdate from '@salesforce/apex/opportunityScoringRecalcController.getNumberOfOppsToUpdate'
import getPicklistValues from '@salesforce/apex/opportunityScoringRecalcController.getPicklistValues'


import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";


export default class OpportunityScoringRecalc extends LightningElement {

    businessUnit;
    businessUnitSelection = true;
    recordTypeSelection = false;
    weightingSelection = false;
    marketSelection = false;
    finalScreen = false;
    errorMessage;
    cardTitle='Select Record Type / Business Unit'
    isError = false;
    isLoading = false;
    userId = Id;
    oppRecordTypes = [
        {label:'ECI / Negotiation',value:'ECI_Negotiation'}, //0126F0000012HrSQAU
        {label:'Tender',value:'Tender'} //0126F0000012HrTQAU
    ];
    businessUnitOptions = [{}];
    weightingOptions=[
        {label:"0.5x",value:"0.5"},
        {label:"1x",value:"1"},
        {label:"3x",value:"3"}    
    ];
    defaultRT = '0126F0000012HrTQAU';
    selectedRT;
    marketOptions = [];
    selectedMarkets = [];
    noMarketsSelected = true;
    marketOne = false;
    oppOne = false;
    oppsToUpdate = 0;
    oppsUpdated = 0;
    oneOppUpdated = false;
    fieldList = {};
    updatedFieldList = {};
    
    /*@wire(getObjectInfo, {objectApiName:OPPORTUNITY_OBJECT})
    objectInfo;

    get oppRecordTypes() {
        console.log(this.objectInfo);
        const rtis = this.objectInfo.data.recordTypeInfos;
        var recordTypeList = [];
        Object.keys(rtis).forEach(element => {
            console.log(element);
            recordTypeList.push(rtis[element].name);
         });
        return recordTypeList;
    }*/

    connectedCallback(){

        getPicklistValues({objectName:'Opportunity', picklistName:'Buildcorp_Business_Unit__c'})
            .then((result) => {
                console.log('Business Units retrieved: ');
                console.log(result);
                this.businessUnitOptions = result;
            })
            .catch((error) => {
                this.isError = true;
                this.errorMessage = JSON.stringify(error);
                console.log(JSON.stringify(error));
            })

        /*getUserBusinessUnit ({ userID : Id})
            .then((result) => {
                console.log('Business Unit Retrieved: '+result);
                this.isError = false;
                this.businessUnit = result;
                if(result == null || result == undefined) {
                    this.businessUnitSelection = true;
                    this.cardTitle = 'Select Business Unit';
                }
                else{
                    this.businessUnitSelection = false
                    this.recordTypeSelection = true;
                    this.cardTitle = 'Select Record Type';
                }
            })
            .catch((error) => {
                this.isError = true;
                this.errorMessage = JSON.stringify(error);
                console.log(JSON.stringify(error));
            });*/

    }


    handleBUSubmit(event){
        event.preventDefault();
        //const fields = event.detail.fields;
        //this.template.querySelector('lightning-record-edit-form').submit(fields);
        //this.businessUnit = fields.Business_Unit__c;
        this.businessUnitSelection = false;
        this.marketSelection = true;
        this.cardTitle = 'Market Selection';
    }

    handleRTChange(event){
        this.selectedRT = event.detail.value;
        console.log(this.selectedRT);
    }

    handleBUChange(event){
        this.businessUnit = event.detail.value;
        console.log(this.businessUnit);
    }

    handleBackToRT(){
        this.selectedRT = null;
        this.businessUnit = null;
        this.marketSelection = false;
        this.fieldList = {};
        this.updatedFieldList = {};
        this.marketOptions = [];
        this.oppsToUpdate = null;
        this.businessUnitSelection = true;
    }

    handleRTSubmit(event){
        /*this.isLoading = true;
        
        this.recordTypeSelection = false;
        this.weightingSelection = true;
        this.cardTitle = 'Scoring Weights'*/
        event.preventDefault();
        this.isLoading = true;
        this.businessUnitSelection = false;
        this.recordTypeSelection = false;
        this.marketSelection = true;
        this.cardTitle = 'Market Selection';
        console.log(this.marketOptions);
        console.log(this.marketOptions.length);
        if(this.marketOptions == null || this.marketOptions.length == 0){
            getMarketOptions({businessUnit:this.businessUnit})
            .then((result) =>{
                console.log('Sector__c values retrieved:');
                console.log(result);
                for (var i = 0; i < result.length; i++){
                    var resultString = result[i];
                    this.marketOptions.push({label:resultString,value:resultString});
                }
                getNumberOfOppsToUpdate({businessUnit:this.businessUnit, recordTypeName:this.selectedRT, marketValues:[]})
                    .then((result) => {
                        console.log('Number of Opps to Update: '+result);
                        this.oppsToUpdate = result;
                        this.isLoading = false;
                    })
                    .catch((error) =>{
                        this.isError = true;
                        this.errorMessage = JSON.stringify(error);
                        console.log(JSON.stringify(error));
                        this.isLoading = false;
                    })
            })
            .catch((error) =>{
                this.isError = true;
                this.errorMessage = JSON.stringify(error);
                console.log(JSON.stringify(error));
                this.isLoading = false;
            })
        }
        else{
            this.isLoading = false;
        }
        
    }

    handleMarketSelection(event){
        //console.log(JSON.stringify(event));
        console.log(JSON.stringify(event.detail));
        console.log(JSON.stringify(event.detail.value));
        this.selectedMarkets = event.detail.value;
        if(this.selectedMarkets.length == 0) this.noMarketsSelected = true;
        else this.noMarketsSelected = false;
        if(this.selectedMarkets.length == 1) this.marketOne = true;
        else this.marketOne = false;
        getNumberOfOppsToUpdate({businessUnit:this.businessUnit, recordTypeName:this.selectedRT, marketValues:this.selectedMarkets})
        .then((result) => {
            console.log('Number of Opps to Update: '+result);
            this.oppsToUpdate = result;
            if(result == 1) this.oppOne = true;
            else this.oppOne = false;
        })
        .catch((error) =>{
            this.isError = true;
            this.errorMessage = JSON.stringify(error);
            console.log(JSON.stringify(error));
        })
    }

    handleMarketSave(){
        this.isLoading = true;
        getFieldStringListFromFieldSet({businessUnitName:this.businessUnit, recordTypeName:this.selectedRT, sectorList:this.selectedMarkets})
            .then((result2) => {
                console.log('Fields retrieved:');
                console.log(result2);
                this.fieldList = Object.entries(result2).map(([key, value]) => ({
                    key,
                    value
                }));
                this.updatedFieldList = JSON.parse(JSON.stringify(this.fieldList));
                for (var index of this.updatedFieldList){
                    //var field = index.value[0];
                    //console.log(field);
                    //var map = {key:index,value:[{id:field.id, label:field.label, multiplier:"1",values:field.values}]};
                    //var map = [{id:field.id, label:field.label, multiplier:"1",values:field.values}];
                    //console.log(map);
                    //this.updatedFieldList.index = map;
                    //this.updatedFieldList.push()
                    index.value[0].multiplier = "1";
                }
                console.log(this.fieldList);
                console.log(this.updatedFieldList);
                this.isLoading = false;
            })
            .catch((error) => {
                this.isError = true;
                this.marketSelection = false;
                this.weightingSelection = false;
                this.errorMessage = JSON.stringify(error);
                console.log(JSON.stringify(error));
                this.isLoading = false;
            });
        this.marketSelection = false;
        this.weightingSelection = true;
        this.cardTitle = 'Scoring Weights'
    }

    handleMultiplierChange(event){
        console.log(JSON.stringify(event.currentTarget.dataset.id));
        console.log(JSON.stringify(event.detail.value));

        var index = parseInt(event.currentTarget.dataset.id);
        var multiplierValue = event.detail.value;
        
        var tempFieldList = JSON.parse(JSON.stringify(this.updatedFieldList));
        console.log(tempFieldList[index].value[0]);//.set('multiplier',multiplierValue);

        tempFieldList[index].value[0].multiplier = multiplierValue;

        for(let i = 0; i < this.selectedMarkets.length; i++){
            tempFieldList[index].value[0].Multipliers[i] = multiplierValue;
        }

        this.updatedFieldList = tempFieldList;

        console.log(this.updatedFieldList);

    }

    handleWeightingSave(){

        this.isLoading = true;
        var updatedValues = {};
        var weightingsList = {};

        for (var field of this.updatedFieldList){
            //updatedValues.set(field.value[0].id,field.value[0].multiplier);
            updatedValues[field.value[0].id] = field.value[0].multiplier;
            //var fieldMap = {key:field.value[0].id,value:field.value[0].multiplier};
            //console.log(fieldMap);
            //updatedValues.push(fieldMap);
            weightingsList[field.key] = field.value[0].multiplier;
        }
        console.log(weightingsList);
        updateWeightings({ weightings : updatedValues, sectorList : this.selectedMarkets})
        .then((result) =>{
            console.log(result);
            //var updatedFieldListList = [this.updatedFieldList];
            //console.log(updatedFieldListList);
            CalculateOpportunityScoreWeighted({businessUnitName:this.businessUnit,recordTypeName:this.selectedRT,sectorNames:this.selectedMarkets, weightingList:weightingsList})
                .then((result2) =>{
                    console.log('it was done? '+result2+'opps were updated.');
                    this.oppsUpdated = result2;
                    if(result2 == 1) this.oneOppUpdated = true;
                    this.isLoading = false;
                    this.weightingSelection = false;
                    this.cardTitle = 'Results'
                    this.finalScreen = true;
                })
                .catch((error2) => {
                    this.weightingSelection = false;
                    this.isError = true;
                    this.errorMessage = error2.body.message;
                    this.isLoading = false;
                    console.log(error2);
                });
        })
        .catch((error) => {
            this.isError = true;
            this.errorMessage = JSON.stringify(error);
            console.log(JSON.stringify(error));
        });
    }

    handleBackToMarket(){
        this.isLoading = true;
        this.marketSelection = true;
        this.selectedMarkets = [];
        this.noMarketsSelected = true;
        this.fieldList = {};
        this.updatedFieldList = {};
        this.weightingSelection = false;
        this.isLoading = false;
    }

    

    restartProcess(){
        
        /*this.weightingSelection = false;
        this.marketSelection = false;
        this.finalScreen = false;
        this.errorMessage = null;
        this.isError = false;
        this.isLoading = true;
        this.selectedRT = null;
        this.marketOptions = [];
        this.selectedMarkets = [];
        this.noMarketsSelected = true;
        this.marketOne = false;
        this.oppsToUpdate = 0;
        this.oppsUpdated = 0;
        this.oneOppUpdated = false;
        this.fieldList = {};
        this.updatedFieldList = {};
        getUserBusinessUnit ({ userID : Id})
            .then((result) => {
                console.log('Business Unit Retrieved: '+result);
                this.isError = false;
                this.businessUnit = result;
                if(result == null || result == undefined) {
                    this.businessUnitSelection = true;
                    this.cardTitle = 'Select Business Unit';
                }
                else{
                    this.businessUnitSelection = false
                    this.recordTypeSelection = true;
                    this.cardTitle = 'Select Record Type';
                }
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.isError = true;
                this.errorMessage = JSON.stringify(error);
                console.log(JSON.stringify(error));
            });*/
        window.location.reload();
    }

}