
package com.mycompany.version1;

/**
 *
 * @author eleni
 */
public class Account {
    
    private int accountId;
    private int beneficiaryId;
    
    public Account(int accountId,int beneficiaryId){
        this.accountId=accountId;
        this.beneficiaryId=beneficiaryId;
    }
    
    public int getAccountId(){
        return accountId;
    }
    
    public void setAccountId(int accountId){
        this.accountId=accountId;
    }
    
    public int getBeneficiaryId(){
        return beneficiaryId;
    }
    
    public void setBeneficiaryId(int beneficiaryId){
        this.beneficiaryId=beneficiaryId;
    }
    
}
