
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
    
    @GetMapping("/beneficiaries/{id}")
    public Object getBenInfo(@PathVariable Long id){
        return benservice.getBenInfo(id);    
    }
    
    @GetMapping("/accounts/{id}")
    public Object getBenAccounts(@PathVariable Long id){
        return benservice.getBenAccounts(id);    
    }
    
    @GetMapping("/transactions/{id}")
    public Object getBenTransactions(@PathVariable Long id){
        return benservice.getBenTransactions(id);    
    }
    
    @GetMapping("/balance/{id}")
    public Object getBalance(@PathVariable Long id){
        return benservice.getBalance(id);    
    }
    
    @GetMapping("/maxWithdrawal/{id}")
    public Object getMaxWithdrawal(@PathVariable Long id){
        return benservice.getMaxWithdrawal(id);    
    }
            
}
