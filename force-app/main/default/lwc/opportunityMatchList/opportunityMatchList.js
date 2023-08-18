import { LightningElement, wire, api, track } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from "lightning/refresh";
import RetrieveMatchingOpportunities from '@salesforce/apex/OpportunityMatchListController.RetrieveMatchingOpportunities'
import GetColumnsFromFieldSet from '@salesforce/apex/OpportunityMatchListController.GetColumnsFromFieldSet'

/*  TO-DO:
- Fix match percent colouring
- Update Apex controller to return Map<Opportunity,Double> where Double is Match Pct, use that (instead of custom field)
- Fix Opportunity Name sorting (currently it's sorting by the Opp ID)
- Fix table height when not enough records to fill table
- Refresh button
*/

export default class DatatableExample extends LightningElement {
    isLoading = true;
    tableHeight = 'height:100px';
    pageSizeOptions = [10,20,50,100];
    totalRecords = 0;
    pageSize;
    totalPages;
    pageNumber = 1;
    rowNumberOffset = 0;
    recordsToDisplay = [];
    isError = false;
    errorMessage;


    @api recordId;

    @track columns;
    @track defaultSortDirection;
    @track data;
    @track sortDirection;
    @track sortedBy;
    @track textColour;

    connectedCallback(){
        GetColumnsFromFieldSet ({ opportunityId : this.recordId })
            .then((result2) => {
                this.columns = result2.map(row =>{
                    return {...row};
                })
                console.log(JSON.stringify(this.columns));
            })
            .catch((error) => {
                this.isError = true;
                this.isLoading = false;
                this.errorMessage = error.body.message;
            });


        RetrieveMatchingOpportunities({ opportunityToMatchId : this.recordId })
            .then((result) => {
                this.data = result.map(row =>{
                    const recordURL = '/lightning/r/'+row.Id+'/view';
                    var textColour;
                    //const accountURL = '/lightning/r/'+row.AccountId+'/view';
                    if(row.Match_Percent__c >= 50 && row.Match_Percent__c < 65) this.textColour = 'red';
                    else if (row.Match_Percent__c >= 65 && row.Match_Percent__c < 80) this.textColour = 'orange';
                    else this.textColour = 'green';
                    return {...row,textColour, recordURL};
                });
                this.sortedBy = 'Match_Percent__c';
                this.sortDirection = 'desc';
                this.sortData('Match_Percent__c','desc');
                this.isLoading = false;
                this.totalRecords = result.length;
                this.pageSize = this.pageSizeOptions[0];
                this.isError = false;
                this.errorMessage = '';
                this.paginationHelper();
                console.log(JSON.stringify(this.data));
            })
            .catch((error) =>{
                console.log('some error happened');
                this.isLoading = false;
                this.isError = true;
                this.errorMessage = error.body.message;
                this.totalRecords = 0;
                this.pageNumber = 1;
                this.totalPages = 1;
                this.tableHeight = this.tableHeight+';background-color: white; color: red; font-size:large';

            });

    }

    /*@track _wiredOppResult;

    @wire(RetrieveMatchingOpportunities, {opportunityToMatchId:'$recordId'}) 
    wiredOpportunities(oppResult){
        
        var {data,error} = oppResult;
        console.log('Result: '+JSON.stringify(oppResult));
        this._wiredOppResult = oppResult;
        
        if (data){
            console.log('some data happened');
            this.data = data.map(row =>{
                const recordURL = '/lightning/r/'+row.Id+'/view';
                var textColour;
                //const accountURL = '/lightning/r/'+row.AccountId+'/view';
                if(row.Match_Percent__c >= 50 && row.Match_Percent__c < 65) this.textColour = 'red';
                else if (row.Match_Percent__c >= 65 && row.Match_Percent__c < 80) this.textColour = 'orange';
                else this.textColour = 'green';
                return {...row,textColour, recordURL};
            })
            this.sortedBy = 'Match_Percent__c';
            this.sortDirection = 'desc';
            this.sortData('Match_Percent__c','desc');
            this.isLoading = false;
            this.totalRecords = data.length;
            this.pageSize = this.pageSizeOptions[0];
            this.isError = false;
            this.errorMessage = '';
            this.paginationHelper();
            console.log(JSON.stringify(this.data));
        }
        else if (error){
            console.log('some error happened');
            this.isLoading = false;
            this.isError = true;
            this.errorMessage = error.body.message;
        }
        
    };

    @wire(GetColumnsFromFieldSet, {opportunityId:'$recordId'}) wiredColumns({error,data}){
        if (data){
            this.columns = data.map(row =>{
                return {...row};
            })
            console.log(JSON.stringify(this.columns));
        }
        else if (error){
            this.isError = true;
            this.isLoading = false;
            this.errorMessage = error.body.message;
        }
        
    };*/

    

    refreshTable(event){

        this.isLoading = true;

        GetColumnsFromFieldSet ({ opportunityId : this.recordId })
            .then((result2) => {
                this.columns = result2.map(row =>{
                    return {...row};
                })
                console.log(JSON.stringify(this.columns));
            })
            .catch((error) => {
                this.isError = true;
                this.isLoading = false;
                this.errorMessage = error.body.message;
            });

        RetrieveMatchingOpportunities({ opportunityToMatchId : this.recordId })
            .then((result) => {
                this.data = result.map(row =>{
                    const recordURL = '/lightning/r/'+row.Id+'/view';
                    var textColour;
                    //const accountURL = '/lightning/r/'+row.AccountId+'/view';
                    if(row.Match_Percent__c >= 50 && row.Match_Percent__c < 65) this.textColour = 'red';
                    else if (row.Match_Percent__c >= 65 && row.Match_Percent__c < 80) this.textColour = 'orange';
                    else this.textColour = 'green';
                    return {...row,textColour, recordURL};
                });
                this.sortedBy = 'Match_Percent__c';
                this.sortDirection = 'desc';
                this.sortData('Match_Percent__c','desc');
                this.isLoading = false;
                this.totalRecords = result.length;
                this.pageSize = this.pageSizeOptions[0];
                this.isError = false;
                this.errorMessage = '';
                this.paginationHelper();
                console.log(JSON.stringify(this.data));
            })
            .catch((error) =>{
                console.log('some error happened');
                this.isLoading = false;
                this.isError = true;
                this.errorMessage = error.body.message;
                this.totalRecords = 0;
                this.pageNumber = 1;
                this.totalPages = 1;
                this.tableHeight = this.tableHeight+';background-color: white; color: red; font-size:large';
            });

        
        //this.connectedCallback();
        //console.log('Refreshing...');
        //console.log('Original wiredOppResult: '+JSON.stringify(this._wiredOppResult));
        //this.isLoading = true;
        /*return refreshApex(this._wiredOppResult).then((result)=>{
            console.log('Results: '+JSON.stringify(result));
        });*/
        //console.log('Refresh complete.');
        //console.log('Refreshed wiredOppResult: '+JSON.stringify(this._wiredOppResult));
        //this.isLoading = false;
        /*if(this._wiredOppResult.data){
            console.log('no error!');
            this.isLoading = false;
            this.isError = false;
            this.errorMessage = '';
        }
        else{
            console.log('ERROR!');
            this.isError = true;
            this.errorMessage = this._wiredOppResult.error.body.message;
        }*/
    }

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }
    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }
    get bDisableFirst(){
        return this.pageNumber == 1;
    }

    get bDisableLast(){
        return this.pageNumber == this.totalPages;
    }
    paginationHelper() {
        this.recordsToDisplay = [];
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        if (this.pageNumber <= 1) {
            this.rowNumberOffset = 0;
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.data[i]);
            let displayCount;
            if(this.pageSize > this.data.length){
                displayCount = this.data.length
            }
            else{
                displayCount = this.pageSize;
            }
            if(this.pageNumber > 1) this.rowNumberOffset = this.pageSize*(this.pageNumber-1);
            this.tableHeight = 'height:'+((25*displayCount)+35)+'px';
        }
    }

    doSorting(event) {
        window.console.log(JSON.stringify(event));
        var sortedBy;
        if(event.detail.fieldName == 'recordURL') sortedBy = 'Name';
        else sortedBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.defaultSortDirection = event.detail.sortDirection;
        this.sortData(sortedBy, this.sortDirection);
        this.sortedBy = event.detail.fieldName;

    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
        this.paginationHelper();
    }  


}