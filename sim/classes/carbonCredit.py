import re
from pathlib import Path
from typing import List

class CarbonCredit:
    """
    Represents a carbon credit as a Prolog fact of the form: carbonCredit(Id, CO2, Cost, MaxQuantity).
    """


    PROLOG_PATTERN = re.compile(
        r"^carbonCredit\(\s*(\d+)\s*,\s*([0-9]*\.?[0-9]+)\s*,\s*([0-9]*\.?[0-9]+)\s*,\s*(\d+)\s*\)\s*\.$"
    )

    def __init__(self, id: int, co2: float, costo: float, max_quantita: int):
        self.id = id
        self.co2 = co2
        self.costo = costo
        self.max_quantita = max_quantita

    def __repr__(self):
        return (
            f"CarbonCredit(id={self.id}, co2={self.co2}, "
            f"costo={self.costo}, max_quantita={self.max_quantita})"
        )

    def __str__(self):
        return (
            f"Credit #{self.id}: CO2={self.co2} t, "
            f"costo={self.costo} €/u, max={self.max_quantita}"
        )

    def to_prolog(self) -> str:
        """
        Serializes the object into a Prolog fact–formatted string.
        """
        
        return (
            f"carbonCredit({self.id}, {self.co2}, "
            f"{self.costo}, {self.max_quantita})."
        )

    @classmethod
    def from_prolog(cls, line: str) -> "CarbonCredit":
        """
        Parses a Prolog line of the form
        """
        
        m = cls.PROLOG_PATTERN.match(line.strip())
        if not m:
            raise ValueError(f"Linea non valida per CarbonCredit: {line!r}")
        id_, co2, costo, max_q = m.groups()
        return cls(id=int(id_), co2=float(co2), costo=float(costo), max_quantita=int(max_q))

def load_carbon_credits(path: Path) -> List[CarbonCredit]:
    """
    Loads all carbonCredit facts from a Prolog file, skipping:
        - blank lines
        - comment lines starting with '%'
        - any other lines not beginning with 'carbonCredit'
    """

    
    credits: List[CarbonCredit] = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("%"):
            continue
        if line.startswith("carbonCredit"):
            credits.append(CarbonCredit.from_prolog(line))
    return credits

def save_carbon_credits(credits: List[CarbonCredit], path: Path) -> None:
    """
    Saves a list of CarbonCredit objects in Prolog format (one fact per line).
    """
    
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as f:
        for cc in credits:
            f.write(cc.to_prolog() + "\n")