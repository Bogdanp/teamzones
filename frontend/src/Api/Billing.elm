module Api.Billing
    exposing
        ( SubscriptionStatus(..)
        , Subscription
        , cancelSubscription
        , fetchSubscription
        )

import Api exposing (Errors, Error, Response, deletePlain, getJson)
import Json.Decode as Json exposing (Decoder, (:=), int, string)
import Task exposing (Task)
import Timestamp exposing (Timestamp)


type SubscriptionStatus
    = Pending
    | Active
    | PastDue
    | Canceled


type alias Subscription =
    { status : SubscriptionStatus
    , validUntil : Timestamp
    }


timestamp : Decoder Timestamp
timestamp =
    let
        convert x =
            toFloat x * 1000
    in
        Json.map convert int


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


subscription : Decoder Subscription
subscription =
    Json.object2 Subscription
        ("status" := subscriptionStatus)
        ("validUntil" := timestamp)


cancelSubscription : Task Error (Response String)
cancelSubscription =
    deletePlain "billing/subscriptions/current"


fetchSubscription : Task Error (Response Subscription)
fetchSubscription =
    getJson subscription "billing/subscriptions/current"
