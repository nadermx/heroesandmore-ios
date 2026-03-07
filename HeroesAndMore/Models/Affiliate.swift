import Foundation

struct Affiliate: Codable, Identifiable {
    let id: Int
    let username: String
    let referralCode: String
    let referralUrl: String
    let paypalEmail: String
    let totalReferrals: Int
    let totalEarnings: String
    let pendingBalance: String
    let paidBalance: String
    let isActive: Bool
    let created: String

    enum CodingKeys: String, CodingKey {
        case id, username, created
        case referralCode = "referral_code"
        case referralUrl = "referral_url"
        case paypalEmail = "paypal_email"
        case totalReferrals = "total_referrals"
        case totalEarnings = "total_earnings"
        case pendingBalance = "pending_balance"
        case paidBalance = "paid_balance"
        case isActive = "is_active"
    }
}

struct Referral: Codable, Identifiable {
    let id: Int
    let referredUsername: String
    let created: String

    enum CodingKeys: String, CodingKey {
        case id, created
        case referredUsername = "referred_username"
    }
}

struct AffiliateCommission: Codable, Identifiable {
    let id: Int
    let orderId: Int
    let commissionType: String
    let orderItemPrice: String
    let commissionRate: String
    let commissionAmount: String
    let status: String
    let created: String

    enum CodingKeys: String, CodingKey {
        case id, status, created
        case orderId = "order_id"
        case commissionType = "commission_type"
        case orderItemPrice = "order_item_price"
        case commissionRate = "commission_rate"
        case commissionAmount = "commission_amount"
    }
}

struct AffiliatePayout: Codable, Identifiable {
    let id: Int
    let amount: String
    let paypalEmail: String
    let status: String
    let periodStart: String
    let periodEnd: String
    let created: String

    enum CodingKeys: String, CodingKey {
        case id, amount, status, created
        case paypalEmail = "paypal_email"
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }
}

struct UpdateAffiliateSettingsRequest: Codable {
    let paypalEmail: String

    enum CodingKeys: String, CodingKey {
        case paypalEmail = "paypal_email"
    }
}
