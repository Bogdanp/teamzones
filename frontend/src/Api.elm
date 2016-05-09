module Api ( Errors
           , send, send'
           , get, get'
           , post
           , delete, delete'
           )  where

import Effects exposing (Effects)
import Http.Extra as HttpExtra exposing (..)
import Json.Decode as Json exposing ((:=))
import Time
import Task exposing (Task)


type alias Errors
  = { errors : List String }


type alias Mapper a b
  = Result (Error Errors) (Response a) -> b


decodeErrors : Json.Decoder Errors
decodeErrors =
  Json.map Errors
      ("errors" := Json.list Json.string)


timeout : Time.Time
timeout = 5 * Time.second


prepare : Mapper a b
        -> Json.Value
        -> BodyReader a
        -> RequestBuilder
        -> Effects b
prepare f val reader req =
  req
    |> withHeader "Content-Type" "application/json"
    |> withJsonBody val
    |> withTimeout timeout
    |> HttpExtra.send reader (jsonReader decodeErrors)
    |> Task.toResult
    |> Task.map f
    |> Effects.task


send : Mapper a b -> Json.Value -> Json.Decoder a -> RequestBuilder -> Effects b
send f val dec req =
  prepare f val (jsonReader dec) req


send' : Mapper String b -> Json.Value -> RequestBuilder -> Effects b
send' f val req =
  prepare f val stringReader req


get : String -> Mapper a b -> Json.Decoder a -> Effects b
get endpoint f dec =
  HttpExtra.get ("/api/" ++ endpoint)
    |> withTimeout timeout
    |> HttpExtra.send (jsonReader dec) (jsonReader decodeErrors)
    |> Task.toResult
    |> Task.map f
    |> Effects.task


get' : String -> Mapper String b -> Effects b
get' endpoint f =
  HttpExtra.get ("/api/" ++ endpoint)
    |> withTimeout timeout
    |> HttpExtra.send stringReader (jsonReader decodeErrors)
    |> Task.toResult
    |> Task.map f
    |> Effects.task


delete : String -> Mapper a b -> Json.Decoder a -> Effects b
delete endpoint f dec =
  HttpExtra.delete ("/api/" ++ endpoint)
    |> withTimeout timeout
    |> HttpExtra.send (jsonReader dec) (jsonReader decodeErrors)
    |> Task.toResult
    |> Task.map f
    |> Effects.task


delete' : String -> Mapper String b -> Effects b
delete' endpoint f =
  HttpExtra.delete ("/api/" ++ endpoint)
    |> withTimeout timeout
    |> HttpExtra.send stringReader (jsonReader decodeErrors)
    |> Task.toResult
    |> Task.map f
    |> Effects.task


post : String -> RequestBuilder
post endpoint =
  HttpExtra.post ("/api/" ++ endpoint)
