
package com.mycompany.version1;
/**
 *
 * @author eleni
 */
public class AccountBalance {
    
    private int accountId;
    private double balance;
    
    public AccountBalance(int accountId, double balance){
        this.accountId = accountId;
        this.balance = balance;
    }
    
    public int getAccountId(){
        return accountId;
    }
    
    public void setAccountId(int accountId){
        this.accountId = accountId;
    }
    
    public double getBalance(){
        return balance;
    }
    
    public void setBalance(double balance){
        this.balance = balance;
    }
    
}
