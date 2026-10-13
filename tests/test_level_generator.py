"""Authoring checks: no Godot/device claims."""
import sys,unittest,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"tools"))
import level_generator as g
class GeneratorTests(unittest.TestCase):
 def test_reproducible(self):
  self.assertEqual(g.generate(4,151,200),g.generate(4,151,200))
 def test_diversity(self):
  levels=g.generate(4,151,200)["levels"]
  for a,b in zip(levels,levels[1:]):self.assertLessEqual(g.similarity(a,b)["score"],g.RULES["maximum_neighbor_similarity"])
  signatures={json.dumps([d["holes"],d["mechanics"],d["canyon"],d["targets"],d["conveyors"]],sort_keys=True) for d in levels}
  self.assertEqual(len(signatures),50)
 def test_difficulty_explainable(self):
  d=g.build(201,5,123)
  score=g.difficulty(d)
  self.assertAlmostEqual(score["score"],sum(score["parts"].values()),places=2)
 def test_drafts_not_accepted_without_engine(self):
  self.assertTrue(all(d["generation"]["status"]=="draft" for d in g.generate(5,201,250)["levels"]))
 def test_large_id_no_fake_catalog(self):
  d=g.build(10001,201,123)
  self.assertEqual(d["id"],10001)
  self.assertLess(max(p["end"] for p in json.loads((g.ROOT/"data/campaign.json").read_text())["packages"]),10001)
if __name__=="__main__":unittest.main()
