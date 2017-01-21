{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}

module Main where

import Options.Generic (Generic, ParseRecord, type (<?>))
import Text.Trifecta.Delta (Delta(..))

import qualified Control.Exception
import qualified Data.Text.Lazy.IO
import qualified Dhall.Import
import qualified Dhall.Nix
import qualified Dhall.Parser
import qualified Dhall.TypeCheck
import qualified Nix.Pretty
import qualified Options.Generic

data Options = Options
    { explain :: Bool <?> "Explain error messages in more detail"
    } deriving (Generic)

instance ParseRecord Options

main :: IO ()
main = do
--  options <- Options.Generic.getRecord "Compile Dhall to Nix"

    inText <- Data.Text.Lazy.IO.getContents

    expr <- case Dhall.Parser.exprFromText (Directed "(stdin)" 0 0 0 0) inText of
        Left  err  -> Control.Exception.throwIO err
        Right expr -> return expr

    expr' <- Dhall.Import.load expr
    case Dhall.TypeCheck.typeOf expr' of
        Left  err -> Control.Exception.throwIO err
        Right _   -> return ()

    nix <- case Dhall.Nix.dhallToNix expr' of
        Left err  -> Control.Exception.throwIO err
        Right nix -> return nix
    print (Nix.Pretty.prettyNix nix)