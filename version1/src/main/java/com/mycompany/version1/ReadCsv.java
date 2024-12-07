
package com.mycompany.version1;

import java.io.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;
import org.springframework.core.io.ClassPathResource;

/**
 *
 * @author eleni
 */
public class ReadCsv {
    
    //read beneficiaries.csv and create objects for Beneficiary 
    public static List<Beneficiary> readBeneficiaries(String filename) throws IOException {
        
        List<Beneficiary> beneficiaries = new ArrayList<>();
        try(BufferedReader br = new BufferedReader(new FileReader(new ClassPathResource(filename).getFile()))){
            String line;
            boolean firstLine=true;
            
            while((line=br.readLine()) !=null){
                if(firstLine){
                    firstLine = false;
                    continue;
                }
                String[] fields = line.split(",");
                if(fields.length == 3){
                    int beneficiaryId = Integer.parseInt(fields[0].trim());
                    String firstName = fields[1].trim();
                    String lastName = fields[2].trim();
                    beneficiaries.add(new Beneficiary(beneficiaryId, firstName, lastName));
                }
            }
        }        
        return beneficiaries;
    }
    
    //read accounts.csv and create objects for Account 
    public static List<Account> readAccounts(String filename) throws IOException{
        
        List<Account> accounts = new ArrayList<>();
        try(BufferedReader br = new BufferedReader(new FileReader(new ClassPathResource(filename).getFile()))){
            String line;
            boolean firstLine=true;
            
            while((line=br.readLine()) !=null){
                if(firstLine){
                    firstLine = false;
                    continue;
                }
                String[] fields = line.split(",");
                if(fields.length == 2){
                    int accountId = Integer.parseInt(fields[0].trim());
                    int beneficiaryId = Integer.parseInt(fields[1].trim()); 
                    accounts.add(new Account(accountId, beneficiaryId));
                }
            }
        }
        return accounts;
    }
    
    //read transactions.csv and create objects for Transaction 
    public static List<Transaction> readTransactions(String filename) throws IOException, ParseException{
        
        List<Transaction> transactions = new ArrayList<>();
        SimpleDateFormat dateFormat = new SimpleDateFormat("MM/dd/yy");
         try (BufferedReader br = new BufferedReader(new FileReader(new ClassPathResource(filename).getFile()))) {
            String line;
            boolean firstLine = true;
            
            while ((line = br.readLine()) != null) {
                if (firstLine) {
                    firstLine = false;
                    continue;
                }
                String[] fields = line.split(",");
                if (fields.length == 5) {
                    try{
                    int transactionId = Integer.parseInt(fields[0].trim());
                    int accountId = Integer.parseInt(fields[1].trim());
                    double amount = Double.parseDouble(fields[2].trim());
                    String type = fields[3].trim();
                    Date date = dateFormat.parse(fields[4].trim());
                    transactions.add(new Transaction(transactionId, accountId, amount, type, date));
                    }catch (ParseException | NumberFormatException e){
                        System.err.println("Invalid date format in line:" +line);
                    }
                }
            }
        }        
        return transactions;
    }
    
}
