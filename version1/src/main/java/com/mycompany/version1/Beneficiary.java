
package com.mycompany.version1;

/**
 *
 * @author eleni
 */
public class Beneficiary {
    
    private int beneficiaryId;
    private String firstName;
    private String lastName;
    
    public Beneficiary(int beneficiaryId, String firstName,String lastName){
        this.beneficiaryId=beneficiaryId;
        this.firstName=firstName;
        this.lastName=lastName;
    }
    
    public int getBeneficiaryId(){
        return beneficiaryId;
    }
    
    public void setBeneficiaryId(int beneficiaryId){
        this.beneficiaryId=beneficiaryId;
    }
    
    public String getFirstName(){
        return firstName;
    }
    
    public void setFirstName(String firstName){
        this.firstName=firstName;
    }
    
    public String getLastName(){
        return lastName;
    }
    
    public void setLastName(String lastName){
        this.lastName=lastName;
    }
           
}
