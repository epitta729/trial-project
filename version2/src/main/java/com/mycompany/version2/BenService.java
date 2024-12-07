
package com.mycompany.version2;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.List;
import org.springframework.stereotype.Service;

/**
 *
 * @author eleni
 */
@Service
public class BenService {
    @PersistenceContext
    private EntityManager mng;
    
    //1. Retrieve beneficiary information.
    public Object getBenInfo(Long benId){
        return mng.createNativeQuery("select * from main.getbeninfo(:benId)")
                .setParameter("benId", benId)
                .getResultList();
    }
    //2. Retrieve beneficiary's accounts.
    public List<Object[]> getBenAccounts(Long benId){
        return mng.createNativeQuery("select * from main.getben_accounts(:benId)")
                .setParameter("benId", benId)
                .getResultList();
    }
    //3. Retrieve beneficiary's transactions
    public List<Object[]> getBenTransactions(Long benId){
        return mng.createNativeQuery("select * from main.getben_transactions(:benId)")
                .setParameter("benId", benId)
                .getResultList();
    }
    
    //4. Retrieve beneficiary's account balance
    public List<Object[]> getBalance(Long benId){
        return mng.createNativeQuery("select * from main.getbalance(:benId)")
                .setParameter("benId", benId)
                .getResultList();
    }
    
    //5. Retrieve the maximum withdrawal of a beneficiary for the last month
    public Object getMaxWithdrawal(long benId){
        return mng.createNativeQuery("select * from main.get_max_withdrawal_last_month(:benId)")
                .setParameter("benId", benId)
                .getResultList();
    }
    
}
