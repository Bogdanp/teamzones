module Api
    exposing
        ( Errors
        , Error
        , Response
        , getJson
        , getPlain
        , patchJson
        , patchPlain
        , postJson
        , postPlain
        , deleteJson
        , deletePlain
        )

import HttpBuilder as HB exposing (RequestBuilder, BodyReader)
import Json.Decode as Json exposing ((:=))
import Task exposing (Task)
import Time


type alias Errors =
    { errors : List String }


type alias Error =
    HB.Error Errors


type alias Response a =
    HB.Response a


decodeErrors : Json.Decoder Errors
decodeErrors =
    Json.map Errors
        ("errors" := Json.list Json.string)


timeout : Time.Time
timeout =
    5 * Time.second


prepareJson :
    Json.Value
    -> BodyReader a
    -> RequestBuilder
    -> Task Error (Response a)
prepareJson val reader req =
    req
        |> HB.withHeader "Content-Type" "application/json"
        |> HB.withJsonBody val
        |> HB.withTimeout timeout
        |> HB.send reader (HB.jsonReader decodeErrors)


preparePlain :
    BodyReader a
    -> RequestBuilder
    -> Task Error (Response a)
preparePlain reader req =
    req
        |> HB.withTimeout timeout
        |> HB.send reader (HB.jsonReader decodeErrors)


prefix : String -> String
prefix =
    (++) "/api/"


getJson : Json.Decoder a -> String -> Task Error (Response a)
getJson dec endpoint =
    prefix endpoint
        |> HB.get
        |> preparePlain (HB.jsonReader dec)


getPlain : String -> Task Error (Response String)
getPlain endpoint =
    prefix endpoint
        |> HB.get
        |> preparePlain HB.stringReader


deleteJson : Json.Decoder a -> String -> Task Error (Response a)
deleteJson dec endpoint =
    prefix endpoint
        |> HB.delete
        |> preparePlain (HB.jsonReader dec)


deletePlain : String -> Task Error (Response String)
deletePlain endpoint =
    prefix endpoint
        |> HB.delete
        |> preparePlain HB.stringReader


patchJson : Json.Value -> Json.Decoder a -> String -> Task Error (Response a)
patchJson val dec endpoint =
    prefix endpoint
        |> HB.patch
        |> prepareJson val (HB.jsonReader dec)


patchPlain : Json.Value -> String -> Task Error (Response String)
patchPlain val endpoint =
    prefix endpoint
        |> HB.patch
        |> prepareJson val HB.stringReader


postJson : Json.Value -> Json.Decoder a -> String -> Task Error (Response a)
postJson val dec endpoint =
    prefix endpoint
        |> HB.post
        |> prepareJson val (HB.jsonReader dec)


postPlain : Json.Value -> String -> Task Error (Response String)
postPlain val endpoint =
    prefix endpoint
        |> HB.post
        |> prepareJson val HB.stringReader
