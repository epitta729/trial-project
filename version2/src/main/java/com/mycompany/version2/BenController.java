
package com.mycompany.version2;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 *
 * @author eleni
 */
@RestController
@RequestMapping("/api")
public class BenController {
    
    @Autowired
    private BenService benservice;

    //1. Retrieve beneficiary information.
    @GetMapping("/beneficiaries/{id}")
    public Object getBenInfo(@PathVariable Long id){
        return benservice.getBenInfo(id);    
    }

    //2. Retrieve beneficiary's accounts.
    @GetMapping("/beneficiaries/{id}/accounts")
    public Object getBenAccounts(@PathVariable Long id){
        return benservice.getBenAccounts(id);    
    }

    //3. Retrieve beneficiary's transactions
    @GetMapping("/beneficiaries/{id}/accounts/transactions")
    public Object getBenTransactions(@PathVariable Long id){
        return benservice.getBenTransactions(id);    
    }

    //4. Retrieve beneficiary's account balance
    @GetMapping("/beneficiaries/{id}/accounts/transactions/balance")
    public Object getBalance(@PathVariable Long id){
        return benservice.getBalance(id);    
    }

    //5. Retrieve the maximum withdrawal of a beneficiary for the last month
    @GetMapping("/beneficiaries/{id}/accounts/transactions/maxWithdrawal")
    public Object getMaxWithdrawal(@PathVariable Long id){
        return benservice.getMaxWithdrawal(id);    
    }
            
}
