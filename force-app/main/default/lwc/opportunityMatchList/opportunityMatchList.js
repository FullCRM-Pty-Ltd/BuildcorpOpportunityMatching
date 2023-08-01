import { LightningElement, wire, api, track } from 'lwc';
import RetrieveMatchingOpportunities from '@salesforce/apex/OpportunityMatchListController.RetrieveMatchingOpportunities'
import GetColumnsFromFieldSet from '@salesforce/apex/OpportunityMatchListController.GetColumnsFromFieldSet'

const columns = [
    { label : 'Name', 
    fieldName : 'Record_URL__c', 
    type : 'url', 
    typeAttributes: 
        { label : 
            { fieldName : 'Name' } 
        }, 
    sortable : true},
    { label : 'Stage', fieldName : 'StageName', sortable : true},
    { label : 'Close Date', fieldName : 'CloseDate', sortable : true, type:'date-local'},
    { label : 'Match %', fieldName : 'Match_Percent__c', type:'percent', sortable : true, cellAttributes: { alignment: 'left' }}
];

export default class DatatableExample extends LightningElement {
    @track columns;
    @track data;
    @track defaultSortDirection='desc';
    @track sortDirection = 'desc';
    @track sortedBy = 'Match_Percent__c';

    @api recordId;

    @wire(GetColumnsFromFieldSet, {opportunityId:'$recordId'}) wiredColumns({error,data}){
        if (data){
            this.columns = data;
        }
        else if (error){
            window.console.log(error);
        }
        
    };

    @wire(RetrieveMatchingOpportunities, {opportunityToMatchId:'$recordId'}) wiredOpportunities({error,data}){
        if (data){
            this.data = data;
            this.sortData(this.sortedBy, this.sortDirection);
        }
        else if (error){
            window.console.log(error);
        }
        
    };

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
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
    }  


}