module Api.Billing
    exposing
        ( BillingCycle(..)
        , SubscriptionStatus(..)
        , Subscription
        , SubscriptionPlan
        , cancelSubscription
        , fetchSubscription
        )

import Api exposing (Errors, Error, Response, deletePlain, getJson)
import Json.Decode as Json exposing (Decoder, (:=), int, list, string)
import Task exposing (Task)
import Timestamp exposing (Timestamp)


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
    { plans : List SubscriptionPlan
    , planId : String
    , status : SubscriptionStatus
    , validUntil : Timestamp
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
    Json.object7 SubscriptionPlan
        ("id" := string)
        ("label" := string)
        ("price" := int)
        ("monthlyPrice" := int)
        ("billingCycle" := billingCycle)
        ("members" := int)
        ("summary" := string)


subscription : Decoder Subscription
subscription =
    Json.object4 Subscription
        ("plans" := list subscriptionPlan)
        ("planId" := string)
        ("status" := subscriptionStatus)
        ("validUntil" := timestamp)


cancelSubscription : Task Error (Response String)
cancelSubscription =
    deletePlain "billing/subscriptions/current"


fetchSubscription : Task Error (Response Subscription)
fetchSubscription =
    getJson subscription "billing/subscriptions/current"
