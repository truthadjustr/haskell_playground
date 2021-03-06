import System.Directory
import System.FilePath((</>))
import Control.Applicative((<$>))
import Control.Exception(throw)
import Control.Monad(when,forM_)

-- import System.Exit(ExitCode)
-- import System.Cmd(system)

copyDir ::  FilePath -> FilePath -> IO ()
copyDir src dst = do
  whenM (not <$> doesDirectoryExist src) $
    throw (userError "source does not exist")
  whenM (doesFileOrDirectoryExist dst) $
    throw (userError "destination already exists")

  createDirectory dst
  content <- getDirectoryContents src
  let xs = filter (`notElem` [".", ".."]) content
  forM_ xs $ \name -> do
    let srcPath = src </> name
    let dstPath = dst </> name
    isDirectory <- doesDirectoryExist srcPath
    if isDirectory
      then copyDir srcPath dstPath
      else copyFile srcPath dstPath

  where
    doesFileOrDirectoryExist x = orM [doesDirectoryExist x, doesFileExist x]
    orM xs = or <$> sequence xs
    whenM s r = s >>= flip when r

-- copyDir2 ::  FilePath -> FilePath -> IO ExitCode
-- copyDir2 src dest = system $ "cp -r " ++ src ++ " " ++ dest
--
