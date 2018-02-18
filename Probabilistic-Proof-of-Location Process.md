### Probabilistic-Proof-of-Location

#### A. Proof Generation

1. User visits verifying node $V_0$
2. User signs message $sig_{user} = ECSign(timestamp, K^{private}_{user})$
3. $V_0$ randomly selects $k-1$ verifying nodes $[V_1..V_{k-1}]$
4. $[V_0..V_{k-1}]$ signs ring signature $sig_{ring} = RingSign(sig_{user}, K^{private}_{V_0}, K^{public}_{[V_0..V_{k-1}]})$
5. Proof $Pr = (sig_{user}, sig_{ring})$ proves that there's a $\frac{1}{k}$ probability that the user visited $V_0$ at $timestamp$

#### B. Proof Verification

1. Check that $ECRecover(hash(timestamp), sig_{user}) == user.address$
2. Check that $RingVerify(sig_{ring}, sig_{user}, K^{public}_{[V_0..V_{k-1}]})$

