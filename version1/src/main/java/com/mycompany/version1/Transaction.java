
package com.mycompany.version1;

import java.text.ParseException;
import java.util.Date;

/**
 *
 * @author eleni
 */
public class Transaction {

    private int transactionId;
    private int accountId;
    private double amount;
    private String type;
    private Date date;
    
    public Transaction(int transactionId, int accountId, double amount, String type, Date thedate) throws ParseException {
        this.transactionId = transactionId;
        this.accountId = accountId;
        this.amount = amount;
        this.type = type;        
        this.date = thedate;
    }
    
    public int getTransactionId() {
        return transactionId;
    }
   
    public void setTransactionId(int transactionId) {
        this.transactionId = transactionId;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public double getAmount() {
        return amount;
    }

    public void setAmount(double amount) {
        this.amount = amount;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Date getDate() {
        return date;
    }

    public void setDate(Date date) {
        this.date = date;
    }    
  
}
