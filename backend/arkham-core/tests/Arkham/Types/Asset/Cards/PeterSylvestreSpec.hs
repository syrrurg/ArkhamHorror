module Arkham.Types.Asset.Cards.PeterSylvestreSpec
  ( spec
  )
where

import TestImport

spec :: Spec
spec = describe "Peter Sylvestre" $ do
  it "gives you +1 agility" $ do
    investigator <- testInvestigator "00000" id
    peterSylvestre <- buildAsset "02033"
    game <- runGameTest
      investigator
      [playAsset investigator peterSylvestre]
      (assets %~ insertEntity peterSylvestre)
    withGame
        game
        (map modifierType
        <$> getModifiersFor (TestSource mempty) (toTarget investigator) ()
        )
      `shouldReturn` [SkillModifier SkillAgility 1]
  it "removes one horror at the end of your turn" $ do
    investigator <- testInvestigator "00000" id
    peterSylvestre <- buildAsset "02033"
    game <-
      runGameTest
          investigator
          [ playAsset investigator peterSylvestre
          , AssetDamage (toId peterSylvestre) (TestSource mempty) 0 2
          , ChooseEndTurn (toId investigator)
          ]
          (assets %~ insertEntity peterSylvestre)
        >>= runGameTestOptionMatching
              "use ability"
              (\case
                Run{} -> True
                _ -> False
              )
    updated game peterSylvestre `shouldSatisfy` hasDamage (0, 1)
