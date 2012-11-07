{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
module Main (main) where

import ClassyPrelude.Conduit
import Shelly (shellyNoDir, rm_rf, run_, run, fromText, cd)
import Data.Conduit.Filesystem (sinkFile)
import Text.ProjectTemplate (createTemplate)
import Filesystem (createTree)
import Filesystem.Path (directory)
import Shared

main :: IO ()
main = shellyNoDir $ do
    rm_rf "yesod-scaffold"
    run_ "git" ["clone", ".", "yesod-scaffold"]
    cd "yesod-scaffold"
    forM_ branches $ \branch -> do
        run_ "git" ["checkout", branch]
        unless (branch == master) $ run_ "git" ["merge", master]
        run_ "git" ["diff", "--exit-code"]
        run_ "cabal" ["install", "--only-dependencies"]
        run_ "yesod" ["test"]
        run_ "git" ["clean", "-fxd"]
        files <- run "git" ["ls-tree", "-r", branch, "--name-only"]
        let fp = "hsfiles" </> fromText branch <.> "hsfiles"
        liftIO $ createTree $ directory fp
        liftIO
            $ runResourceT
            $ mapM_ (yield . toPair "yesod-scaffold" . fromText) (lines files)
           $$ createTemplate
           =$ writeFile fp
  where
    toPair root fp = (fp, readFile $ root </> fp)
