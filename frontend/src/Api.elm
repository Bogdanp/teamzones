module Api
    exposing
        ( Errors
        , getJson
        , getPlain
        , postJson
        , postPlain
        , deleteJson
        , deletePlain
        )

import HttpBuilder as HB exposing (Error, Response, RequestBuilder, BodyReader)
import Json.Decode as Json exposing ((:=))
import Time
import Task exposing (Task)


type alias Errors =
    { errors : List String }


type alias RequestPlain msg =
    (Error Errors -> msg) -> (Response String -> msg) -> String -> Cmd msg


type alias RequestJson a msg =
    (Error Errors -> msg) -> (Response a -> msg) -> Json.Decoder a -> String -> Cmd msg


type alias RequestJsonPlain msg =
    (Error Errors -> msg) -> (Response String -> msg) -> Json.Value -> String -> Cmd msg


type alias RequestJsonJson a msg =
    (Error Errors -> msg) -> (Response a -> msg) -> Json.Value -> Json.Decoder a -> String -> Cmd msg


decodeErrors : Json.Decoder Errors
decodeErrors =
    Json.map Errors
        ("errors" := Json.list Json.string)


timeout : Time.Time
timeout =
    5 * Time.second


prepareJson :
    (Error Errors -> msg)
    -> (Response a -> msg)
    -> Json.Value
    -> BodyReader a
    -> RequestBuilder
    -> Cmd msg
prepareJson ferr fok val reader req =
    req
        |> HB.withHeader "Content-Type" "application/json"
        |> HB.withJsonBody val
        |> HB.withTimeout timeout
        |> HB.send reader (HB.jsonReader decodeErrors)
        |> Task.perform ferr fok


preparePlain :
    (Error Errors -> msg)
    -> (Response a -> msg)
    -> BodyReader a
    -> RequestBuilder
    -> Cmd msg
preparePlain ferr fok reader req =
    req
        |> HB.withTimeout timeout
        |> HB.send reader (HB.jsonReader decodeErrors)
        |> Task.perform ferr fok


prefix : String -> String
prefix =
    (++) "/api/"


getJson : RequestJson a msg
getJson ferr fok dec endpoint =
    prefix endpoint
        |> HB.get
        |> preparePlain ferr fok (HB.jsonReader dec)


getPlain : RequestPlain msg
getPlain ferr fok endpoint =
    prefix endpoint
        |> HB.get
        |> preparePlain ferr fok HB.stringReader


deleteJson : RequestJson a msg
deleteJson ferr fok dec endpoint =
    prefix endpoint
        |> HB.delete
        |> preparePlain ferr fok (HB.jsonReader dec)


deletePlain : RequestPlain msg
deletePlain ferr fok endpoint =
    prefix endpoint
        |> HB.delete
        |> preparePlain ferr fok HB.stringReader


postJson : RequestJsonJson a msg
postJson ferr fok val dec endpoint =
    prefix endpoint
        |> HB.post
        |> prepareJson ferr fok val (HB.jsonReader dec)


postPlain : RequestJsonPlain msg
postPlain ferr fok val endpoint =
    prefix endpoint
        |> HB.post
        |> prepareJson ferr fok val HB.stringReader
