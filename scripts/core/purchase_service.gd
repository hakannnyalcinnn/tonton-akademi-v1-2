extends RefCounted
## Future billing boundary. No simulated success, payment UI or entitlement grants.
const FUTURE_PRODUCTS=["crystal_pack","booster_pack","starter_pack","remove_ads"]
func available() -> bool:return false
func purchase(_product: String) -> Dictionary:return {"ok":false,"message":"Gerçek para satın alma bu sürümde etkin değil."}
func restore_purchases() -> Dictionary:return {"ok":false,"message":"Doğrulanmış Google Play Billing servisi bağlı değil."}
