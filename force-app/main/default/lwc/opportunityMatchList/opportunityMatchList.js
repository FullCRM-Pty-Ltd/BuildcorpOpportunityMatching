import { LightningElement, wire, api, track } from 'lwc';
import RetrieveMatchingOpportunities from '@salesforce/apex/OpportunityMatchListController.RetrieveMatchingOpportunities'
import GetColumnsFromFieldSet from '@salesforce/apex/OpportunityMatchListController.GetColumnsFromFieldSet'

/*  TO-DO:
- Fix match percent colouring
- Update Apex controller to return Map<Opportunity,Double> where Double is Match Pct, use that (instead of custom field)
- Fix Opportunity Name sorting (currently it's sorting by the Opp ID)
*/

export default class DatatableExample extends LightningElement {
    isLoading = true;
    tableHeight = 'height:100px';
    pageSizeOptions = [10,20,50,100];
    totalRecords = 0;
    pageSize;
    totalPages;
    pageNumber = 1;
    recordsToDisplay = [];
    isError = false;
    errorMessage;
    @track columns;
    @track data;
    @track defaultSortDirection;
    @track sortDirection;
    @track sortedBy;
    @track textColour;

    get bDisableFirst(){
        return this.pageNumber == 1;
    }

    get bDisableLast(){
        return this.pageNumber == this.totalPages;
    }

    @api recordId;


    @wire(RetrieveMatchingOpportunities, {opportunityToMatchId:'$recordId'}) wiredOpportunities({error,data}){
        if (data){
            this.data = data;
            this.data = data.map(row =>{
                const recordURL = '/lightning/r'+row.Id+'/view';
                var textColour;
                //const accountURL = '/lightning/r/'+row.AccountId+'/view';
                if(row.Match_Percent__c >= 50 && row.Match_Percent__c < 65) this.textColour = 'red';
                else if (row.Match_Percent__c >= 65 && row.Match_Percent__c < 80) this.textColour = 'orange';
                else this.textColour = 'green';
                return {...row,textColour};
            })
            this.sortedBy = 'Match_Percent__c';
            this.sortDirection = 'desc';
            this.sortData('Match_Percent__c','desc');
            this.isLoading = false;
            this.totalRecords = data.length;
            this.pageSize = this.pageSizeOptions[0];
            this.paginationHelper();
            console.log(JSON.stringify(this.data));
        }
        else if (error){
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
            //this.columns = data;
        }
        else if (error){
            window.console.log(error);
        }
        
    };

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
    paginationHelper() {
        this.recordsToDisplay = [];
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.data[i]);
            this.tableHeight = 'height:'+((25*this.pageSize)+35)+'px';
        }
    }

    doSorting(event) {
        window.console.log(JSON.stringify(event));
        this.sortedBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.defaultSortDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortDirection);
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