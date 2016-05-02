module Util where

import String

initials : String -> String
initials name =
  name
    |> String.split " "
    |> List.take 2
    |> List.map (fst << Maybe.withDefault (' ', "") << String.uncons)
    |> String.fromList
    |> String.trimRight
