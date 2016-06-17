module Api.Billing
    exposing
        ( BillingCycle(..)
        , SubscriptionStatus(..)
        , Subscription
        , SubscriptionPlan
        , TransactionType(..)
        , TransactionStatus(..)
        , Transaction
        , cancelSubscription
        , fetchSubscription
        , fetchInvoices
        , fetchInvoice
        , updatePlan
        , updateVatId
        )

import Api exposing (Errors, Error, Response, deletePlain, getJson, postPlain)
import Date exposing (Date)
import Json.Decode as Json exposing (Decoder, (:=), bool, int, list, maybe, string, succeed)
import Json.Decode.Extra exposing ((|:), date)
import Json.Encode
import Task exposing (Task)
import Timestamp exposing (Timestamp)
import Util exposing ((=>))


type BillingCycle
    = Never
    | Month
    | Year


type SubscriptionStatus
    = Pending
    | Active
    | PastDue
    | Canceled


type alias SubscriptionPlan =
    { id : String
    , label : String
    , price : Int
    , monthlyPrice : Int
    , billingCycle : BillingCycle
    , members : Int
    , summary : String
    }


type alias Subscription =
    { needVat : Bool
    , vat : Int
    , vatId : String
    , plans : List SubscriptionPlan
    , planId : String
    , status : SubscriptionStatus
    , validUntil : Timestamp
    }


type TransactionType
    = Sale


type TransactionStatus
    = Settled


type alias Transaction =
    { id : String
    , subscriptionId : String
    , subscriptionPlanId : String
    , subscriptionCountry : String
    , subscriptionVatId : String
    , subscriptionVatPercent : Int
    , transactionId : String
    , transactionAmount : Int
    , transactionType : TransactionType
    , transactionStatus : TransactionStatus
    , createdAt : Date
    , updatedAt : Date
    }


timestamp : Decoder Timestamp
timestamp =
    let
        convert x =
            toFloat x * 1000
    in
        Json.map convert int


billingCycle : Decoder BillingCycle
billingCycle =
    let
        convert s =
            case s of
                "month" ->
                    Month

                "year" ->
                    Year

                _ ->
                    Never
    in
        Json.map convert string


subscriptionStatus : Decoder SubscriptionStatus
subscriptionStatus =
    let
        convert s =
            case s of
                "Pending" ->
                    Pending

                "Active" ->
                    Active

                "PastDue" ->
                    PastDue

                "Canceled" ->
                    Canceled

                _ ->
                    Active
    in
        Json.map convert string


subscriptionPlan : Decoder SubscriptionPlan
subscriptionPlan =
    succeed SubscriptionPlan
        |: ("id" := string)
        |: ("label" := string)
        |: ("price" := int)
        |: ("monthlyPrice" := int)
        |: ("billingCycle" := billingCycle)
        |: ("members" := int)
        |: ("summary" := string)


subscription : Decoder Subscription
subscription =
    succeed Subscription
        |: ("needVat" := bool)
        |: ("vat" := int)
        |: ("vatId" := string)
        |: ("plans" := list subscriptionPlan)
        |: ("planId" := string)
        |: ("status" := subscriptionStatus)
        |: ("validUntil" := timestamp)


transactionType : Decoder TransactionType
transactionType =
    let
        decode s =
            case s of
                "sale" ->
                    Ok Sale

                _ ->
                    Err "invalid transaction type"
    in
        Json.customDecoder string decode


transactionStatus : Decoder TransactionStatus
transactionStatus =
    let
        decode s =
            case s of
                "settled" ->
                    Ok Settled

                _ ->
                    Err "invalid transaction status"
    in
        Json.customDecoder string decode


transaction : Decoder Transaction
transaction =
    succeed Transaction
        |: ("id" := string)
        |: ("subscriptionId" := string)
        |: ("subscriptionPlanId" := string)
        |: ("subscriptionCountry" := string)
        |: ("subscriptionVatId" := string)
        |: ("subscriptionVatPercent" := int)
        |: ("transactionId" := string)
        |: ("transactionAmount" := int)
        |: ("transactionType" := transactionType)
        |: ("transactionStatus" := transactionStatus)
        |: ("createdAt" := date)
        |: ("updatedAt" := date)


cancelSubscription : Task Error (Response String)
cancelSubscription =
    deletePlain "billing/subscriptions/current"


fetchSubscription : Task Error (Response Subscription)
fetchSubscription =
    getJson subscription "billing/subscriptions/current"


fetchInvoices : Task Error (Response (List Transaction))
fetchInvoices =
    getJson (Json.oneOf [ list transaction, succeed [] ]) "billing/invoices"


fetchInvoice : String -> Task Error (Response Transaction)
fetchInvoice invoiceId =
    getJson transaction ("billing/invoices/" ++ invoiceId)


updatePlan : String -> Task Error (Response String)
updatePlan planId =
    postPlain (Json.Encode.object [ "planId" => Json.Encode.string planId ]) "billing/plans"


updateVatId : String -> Task Error (Response String)
updateVatId vatId =
    postPlain (Json.Encode.object [ "vatId" => Json.Encode.string vatId ]) "billing/vat-id"
