class WopiDiscoveryTest < ActiveSupport::TestCase
  # These tests are taken from WOPI official documentation
  # https://github.com/Microsoft/Office-Online-Test-Tools-and-Documentation/
  # blob/master/samples/python/proof_keys/tests.py
  def setup
    @discovery = wopi_discoveries(:first)
  end

  test 'Verify X-WOPI-Proof with current discovery proof key1.' do
    assert @discovery.verify_proof(
      'yZhdN1qgywcOQWhyEMVpB6NE3pvBksvcLXsrFKXNtBeDTPW%2fu62g2t%' \
      '2fOCWSlb3jUGaz1zc%2fzOzbNgAredLdhQI1Q7sPPqUv2owO78olmN74D' \
      'V%2fv52OZIkBG%2b8jqjwmUobcjXVIC1BG9g%2fynMN0itZklL2x27Z2i' \
      'mCF6xELcQUuGdkoXBj%2bI%2bTlKM',
      635655897610773532,
      'IflL8OWCOCmws5qnDD5kYMraMGI3o+T+hojoDREbjZSkxbbx7XIS1Av85' \
      'lohPKjyksocpeVwqEYm9nVWfnq05uhDNGp2MsNyhPO9unZ6w25Rjs1hDF' \
      'M0dmvYx8wlQBNZ/CFPaz3inCMaaP4PtU85YepaDccAjNc1gikdy3kSMeG' \
      '1XZuaDixHvMKzF/60DMfLMBIu5xP4Nt8i8Gi2oZs4REuxi6yxOv2vQJQ5' \
      '+8Wu2Olm8qZvT4FEIQT9oZAXebn/CxyvyQv+RVpoU2gb4BreXAdfKthWF' \
      '67GpJyhr+ibEVDoIIolUvviycyEtjsaEBpOf6Ne/OLRNu98un7WNDzMTQ==',
      'lWBTpWW8q80WC1eJEH5HMnGka4/LUF7zjUPqBwRMO0JzVcnjICvMP2TZP' \
      'B2lJfy/4ctIstCN6P1t38NCTTbLWlXuE',
      'https://contoso.com/wopi/files/vHxYyRGM8VfmSGwGYDBMIQPzuE' \
      '+sSC6kw+zWZw2Nyg?access_token=yZhdN1qgywcOQWhyEMVpB6NE3pv' \
      'BksvcLXsrFKXNtBeDTPW%2fu62g2t%2fOCWSlb3jUGaz1zc%2fzOzbNgA' \
      'redLdhQI1Q7sPPqUv2owO78olmN74DV%2fv52OZIkBG%2b8jqjwmUobcj' \
      'XVIC1BG9g%2fynMN0itZklL2x27Z2imCF6xELcQUuGdkoXBj%2bI%2bTlKM'
    )
  end

  test 'Verify X-WOPI-Proof with current discovery proof key2.' do
    assert @discovery.verify_proof(
      'RLoY%2f3D73%2fjwt6IQqR1wHqCEKDxRf2v0GPDa0ZHTlA6ik1%2fNBHDD' \
      '6bHCI0BQrvacjNBL8ok%2fZsVPI%2beAIA5mHSOUbhW9ohowwD6Ljlwro2' \
      'n5PkTBh6GEYi2afuCIQ8mjXAUdvEDg3um2GjJKtA%3d%3d',
      635655897361394523,
      'x0IeSOjUQNH2pvjMPkP4Jotzs5Weeqms4AlPxMQ5CipssUJbyKFjLWnwPg' \
      '1Ac0XtSTiPD177BmQ1+KtmYvDTWQ1FmBuvpvKZDSKzXoT6Qj4LCYYQ0Txn' \
      'N/OT231+qd50sOD8zAxhfXP56qND9tj5xqoHMa+lbuvNCqiOBTZw5f/dkl' \
      'SK7Wgdx7ST3Dq6S9xxDUfsLC4Tjq+EsvcdSNIWL/W6NRZdyWqlgRgE6X8t' \
      '/2iyyMypURdOW2Rztc6w/iYhbuh22Ul6Jfu14KaDo6YkvBr8iHlK4CcQST' \
      '9i0u044y1Jnh34UK4EPdVRZrvTmeJ/5DFLWOqEwvBlW2bpoYF+9A==',
      'etYRI9UT6q8jA6PHMMmuGa8NbyIlbTHMHmJZqaCOh2GCpv7um2q7+7oaDF' \
      'qAV/UP+2N85yZXvZgt9kTOUCwIdggUQVeJluNCwf1B5NsN/7n2aQF9LnWy' \
      'YK8kK/3xvQKQrj4n24jk2MnHcX1tk8H/qLxq2DbPzi6ROoSgs2ZK8nmzhS' \
      'PF74jnLCrwiwGgnVZV6gIhlAKCcUGtdrT60sgD/wpJGQQ0M59VDQhf1aDj' \
      '5bUotf8RXovY8Gl0lpguvN4+EsEjpbVjdV9hxWs7c03JDdoz7mzFUWErSl' \
      'y9IzYXNfuFZMnSXpF3lGiprVJvW34Bu2gTo/cLq4LQoABkNCmd4g==',
      'https://contoso.com/wopi/files/JIB9h+LJpZWBDwvoIiQ5p3115zJ' \
      'WDecpGF9aCm1vOa5UMllgC7w?access_token=RLoY%2f3D73%2fjwt6IQ' \
      'qR1wHqCEKDxRf2v0GPDa0ZHTlA6ik1%2fNBHDD6bHCI0BQrvacjNBL8ok%' \
      '2fZsVPI%2beAIA5mHSOUbhW9ohowwD6Ljlwro2n5PkTBh6GEYi2afuCIQ8' \
      'mjXAUdvEDg3um2GjJKtA%3d%3d'
    )
  end

  test 'Verify X-WOPI-ProofOld with current discovery proof key1.' do
    assert @discovery.verify_proof(
      'zo7pjAbo%2fyof%2bvtUJn5gXpYcSl7TSSx0TbQGJbWJSll9PTjRRsAbG%' \
      '2fSNL7FM2n5Ei3jQ8UJsW4RidT5R4tl1lrCi1%2bhGjxfWAC9pRRl6J3M1' \
      'wZk9uFkWEeGzbtGByTkaGJkBqgKV%2ffxg%2bvATAhVr6E3LHCBAN91Wi8UG',
      635655898374047766,
      'qQhMjQf9Zohj+S/wvhe+RD6W5TIEqJwDWO3zX9DB85yRe3Ide7EPQDCY9dA' \
      'ZtJpWkIDDzU+8FEwnexF0EhPimfCkmAyoPpkl2YYvQvvwUK2gdlk3WboWOV' \
      'szm17p4dSDA0TDMPYsjaAGHKM/nPnTyIMzRyArEzoy2vNkLEP6qdBIuMP2a' \
      'CtGsciwMjYifHYRIRenB7H7I+FkwH0UaoTUCoo2PJkyZjy1nK6OwGVWaWG0' \
      'G8g7Zy+K3bRYV+7cNaM5SB720ezhmYYJJvsIdRvO7pLsjAuTo4KJhvmVFCi' \
      'pwyCdllVHY83GjuGOsAbHIIohl0Ttq59o0jp4w2wUs8U+mQ==',
      'PjKR1BTNNnfOrUzfo27cLIhlrbSiOVZaANadDyHxKij/77ZYId+liyXoawv' \
      'vQQPgnBH1dW6jqpr6fh5ZxZ9IOtaV+cTSUGnGdRSn7FyKs1ClpApKsZBO/i' \
      'RBLXw3HDWOLc0jnA2bnxY8yqbEPmH5IBC9taYzxnf7aGjc6AWFHfs6AEQ8l' \
      'Mio6UoASNzjy3VVNzUX+CK+e5Z45coT0X60mjaJmidGfPdWIfyUw8sSuUwx' \
      'Qa1uNXAd8IceRUL7j5s9/kk7EwsihCw1Y3L+XJGG5zMsGhM9bTK5mvxj30U' \
      'dmZORouNHdywOfdHaB1iOeKOk+yvWFMW3JsYShWbUhZUOEQ==',
      'https://contoso.com/wopi/files/RVQ29k8tf3h8cJ/Endy+aAMPy0iG' \
      'hLatGNrhvKofPY9p2w?access_token=zo7pjAbo%2fyof%2bvtUJn5gXpY' \
      'cSl7TSSx0TbQGJbWJSll9PTjRRsAbG%2fSNL7FM2n5Ei3jQ8UJsW4RidT5R' \
      '4tl1lrCi1%2bhGjxfWAC9pRRl6J3M1wZk9uFkWEeGzbtGByTkaGJkBqgKV%' \
      '2ffxg%2bvATAhVr6E3LHCBAN91Wi8UG'
    )
  end

  test 'Verify X-WOPI-ProofOld with current discovery proof key2.' do
    assert @discovery.verify_proof(
      '2rZvm60097vFfXK01cylEhaYU26CbpsoEdVdk%2fDK2JzBjg185nE69CCkl' \
      'Y36u2Thrx9DyLdNZGsbRorX12TK%2b6XW8ka%2fKSukXl9N3dkOLlZxe%2b' \
      'TQhhDlcymhYZ%2fnYx282ZrnI8gdIob0nmlYAIaSDRg0ZVx%2f%2bnSV8X8' \
      'cHsiMvftBkQQ%2bJgqOU1le3OimjHOiDg%3d%3d',
      635655899172093398,
      'nLwR4nbFq8F/RLuAQ0Yby/avSJcpktZh+JlWonkXuVunTw+BZ+F84c3i1+0' \
      'o7QoPQRkYmy/HEYhFoYVghkhQJzFXf98sYxb52SvDz/pl3G/gTgCcdcqkfR' \
      'SMtaslkRX1VKC3YX42ksIL0LzM4wiCOJfT70i+2Yr5EQRWi6b2JELrAqPuN' \
      'kxpuUUZ3DtEXsO9r6a4WkEwJesmqcqaQpMUvQ6cAkShgY7p0gAQeL//GG6w' \
      'SpDaaA3QqKBcmBgzAatCaqg9NXiPjviZdoHgnbIRjBEhtH/WG00py/tsGMo' \
      'Ih6R9VfnC4jEWWymB5mIiXxW1gBuL63QvQqiL1S8FQ2Xo+g==',
      'M7R/iGyWInpWKl1+aAPuB2yVAwWaHTi504c87V0p35PzDyTh+K6fn20ygKm' \
      'xf9suN9pq+/rMtUXhvM/zCyam0dZFuWpFOI22U0AjQxIJ4ZBH+zT+e/QeNm' \
      'S7w4ctxUnDJ0zGsJ/DxaC0/DAkiIMOfXgb8FMPA/Z/HY+e1C6rRsoMXy0XG' \
      'oTwzIDiI6wzPVr6FJpkktwO+eCNMyxnAODhlK+nubIhvmVEzWtenMXX8a2e' \
      'J3mFquNC7Le6shiUxZA03MgqknwjasNaGPrdpJYjxCwzH3LnHPOHxVY2Hcj' \
      'jTQTNHO8HEPCoSw9bi5a7XFS2loQM/tm0WknBe9+q4fpMMw==',
      'https://contoso.com/wopi/files/s/3BPN8mUjJJAQS+aOFtFm6CU+YN' \
      'pRICIR2M7mQLeQ90BA?access_token=2rZvm60097vFfXK01cylEhaYU26' \
      'CbpsoEdVdk%2fDK2JzBjg185nE69CCklY36u2Thrx9DyLdNZGsbRorX12TK' \
      '%2b6XW8ka%2fKSukXl9N3dkOLlZxe%2bTQhhDlcymhYZ%2fnYx282ZrnI8g' \
      'dIob0nmlYAIaSDRg0ZVx%2f%2bnSV8X8cHsiMvftBkQQ%2bJgqOU1le3Oim' \
      'jHOiDg%3d%3d'
    )
  end

  test 'Verify X-WOPI-Proof with old discovery proof key1.' do
    assert @discovery.verify_proof(
      'pbocsujrb9BafFujWh%2fuh7Y6S5nBnonddEzDzV0zEFrBwhiu5lzjXRezX' \
      'DC9N4acvJeGVB5CWAcxPz6cJ6FzJmwA4ZgGP6FaV%2b6CDkJYID3FJhHFrb' \
      'w8f2kRfaceRjV1PzXEvFXulnz2K%2fwwv0rF2B4A1wGQrnmwxGIv9cL5PBC4',
      635655898062751632,
      'qF15pAAnOATqpUTLHIS/Z5K7OYFVjWcgKGbHPa0eHRayXsb6JKTelGQhvs7' \
      '4gEFgg1mIgcCORwAtMzLmEFmOHgrdvkGvRzT3jtVVtwkxEhQt8aQL20N0Nw' \
      'n4wNah0HeBHskdvmA1G/qcaFp8uTgHpRYFoBaSHEP3AZVNFg5y2jyYR34nN' \
      'j359gktc2ZyLel3J3j7XtyjpRPHvvYVQfh7RsArLQ0VGp8sL4/BDHdSsUyJ' \
      '8FXe67TSrz6TMZPwhEUR8dYHYek9qbQjC+wxPpo3G/yusucm1gHo0BjW/l3' \
      '6cI8FRmNs1Fqaeppxqu31FhR8dEl7w5dwefa9wOUKcChF6A==',
      'KmYzHJ9tu4SXfoiWzOkUIc0Bh8H3eJrA3OnDSbu2hT68EuLTp2vmvvFcHyH' \
      'IiO8DuKj7u13MxkpuUER6VSIJp3nYfm91uEE/3g61V3SzaeRXdnkcKUa5x+' \
      'ulKViECL2n4mpHzNnymxojFW5Y4lKUU4qEGzjE71K1DSFTU/CBkdqycsuy/' \
      'Oct8G4GhA3O4MynlCf64B9LIhlWe4G+hxZgxIO0pq7w/1SH27nvScWiljVq' \
      'gOAKr0Oidk/7sEfyBcOlerLgS/A00nJYYJk23DjrKGTKz1YY0CMEsROJCMi' \
      'W11caxr0aKseOYlfmb6K1RXxtmiDpJ2T4y8jintjEdzEWDA==',
      'https://contoso.com/wopi/files/DJNj59eQlM6BvwzAHkykiB1vNOWR' \
      'uxT487+guv3v7HexfA?access_token=pbocsujrb9BafFujWh%2fuh7Y6S' \
      '5nBnonddEzDzV0zEFrBwhiu5lzjXRezXDC9N4acvJeGVB5CWAcxPz6cJ6Fz' \
      'JmwA4ZgGP6FaV%2b6CDkJYID3FJhHFrbw8f2kRfaceRjV1PzXEvFXulnz2K' \
      '%2fwwv0rF2B4A1wGQrnmwxGIv9cL5PBC4',
    )
  end

  test 'Verify X-WOPI-Proof with old discovery proof key2.' do
    assert @discovery.verify_proof(
      '%2foBUJRjT2EVSVaB0Bjl2BCC7bXkN674bwppkzj2H9Elj2G%2bVGl06EzV' \
      'gv62BqIW17gZZUweK%2fBPCOWN%2bbwoHy2BWES7J4OrDgFpErCsRmRkUr9' \
      '82LaFC2Nxb0%2bH6u6MrWfRMK5dX6w0cltOtRU%2fnsJ9JasAq0J2%2fEzh' \
      'RbQwIyMQ%3d',
      635655898147049273,
      'egEcu5FlU9q+u+d5WQ/Z1nYbttR+0iWsLh2BgiyzAq93sQFyvQ5XSCW5i/V' \
      '7rt9HDewnmvIXsak5ayeoX2aDNgsVM8gSI533tO9dv/33vBM6MAzNLXP3v5' \
      'rNI/TaTXcfm4Q1bIoE5RFVZUSPH73B3p1Oon0Hhhd1CysFGv6ue00CT1Dgp' \
      'u/w5cVElQxZmWmguD5hEFgmg9IGKuSJ1CdVeJLcTbdKWhJnTl/G4+SpXfWB' \
      'nvTBXSzLK+PdtfVCxh/bPO/FJNRWNAg+UgdVAXnLN79faiioG27lXGVrodp' \
      'VgW8qdANvDkjQbn7z7jXmQmv8ksVQgHfZel963NXRty5pDg==',
      'AQUuboqy0JFnMgWfaz8o6V3YDCd6fwQlmkM5cNxCK1ikLK03W4R3xjazBev' \
      'Nja70i3y0JYZ3GvTlJy4ZsEfYf+DRhfzgSuxExpTvNB5RMUvi/kNRTlrMNm' \
      '6JQrLr2rTY5A+FvQ8YErnKSl5gqh9vb4b47sRdQNvYL5hiVI+Qd4AGAwN9d' \
      'Sq/IJo3jHtivPSGMEfuqozoX3/GQEYfRf5dv58Rjeo5XRiDvuSDhPOacdoL' \
      '/DFc/ksC0u9vN4qmoTSvt313p/FhFZ9T3NZYi/dv63XP8DJLWs3HMauzGiK' \
      'FbvKaxDYb2K2llM1CRM2PbKproARMUR6oYYzwNKtg/Q7qIw==',
      'https://contoso.com/wopi/files/UzfEboK8w9Eal86Vk4xzIkGwUeMA' \
      'iFaNF14FfQETzQ72LPw?access_token=%2foBUJRjT2EVSVaB0Bjl2BCC7' \
      'bXkN674bwppkzj2H9Elj2G%2bVGl06EzVgv62BqIW17gZZUweK%2fBPCOWN' \
      '%2bbwoHy2BWES7J4OrDgFpErCsRmRkUr982LaFC2Nxb0%2bH6u6MrWfRMK5' \
      'dX6w0cltOtRU%2fnsJ9JasAq0J2%2fEzhRbQwIyMQ%3d'
    )
  end

  test 'Invalid proof key1.' do
    assert_not @discovery.verify_proof(
      '7DHGrfxYtgXxfaXF%2benHF3PTGMrgNlYktkbQB8q%2fn2aQwzYQ6qTmqNJR' \
      'nJm5QIMXS7WbIxMy0LXaova2h687Md4%2bNTazty3P7HD3j5q9anbCuLsUJH' \
      'tSXfKANUetLyAjFWq6egtMZJSHzDajO0EaHTeA9M7zJg1j69dEMoLmIbxP03' \
      'kwAvBrdVQmjFdFryKw',
      635655899260461032,
      'Y/wVmPuvWJ5Q/Gl/a5mCkTrCKbfHWYiMG6cxmJgD+M/yYFzTsfcgbK2IRAlC' \
      'R2eqGx3a5wh5bQzlC6Y/sKo2IE9Irz/NHFpV55zYfdwDi5ccwXSd34jWVUgk' \
      'M3uL1r6KVmHcQH/ew10p54FVatXatuGp2Y+cq9BScYV1a45U8fs9zYoZcTAY' \
      'vdWeYXmJbRGMOLLxab3fOiulPmbw+gOqpYPbuInc0yut6eGxAUmY1ENxpN7n' \
      'bUqI3LbJvmE3PuX8Ifgg3RCsaFJEqC6JR36MjG+VqoKaFI6hh/ZWLR4y7FBa' \
      'rSmQBr2VlAHrcWCJIMXoOOKaHdsDfNCb3A24LFvdAQ==',
      'Pdbk1FoAB4zhxaDptfVOwTCmrNgWO6zdokoI3VYO8eshE9nJR1Rzr9K2666z' \
      'a29IfT050jJX0EBanIXAawL4rFA6swPHYQAzf3pWJqwvqIbaLYvi4104IBWh' \
      'm9XdZ7C1jDUmG8DgwbKrXZfg7xxZ/hzPlwEp5Y9ZijD/ReAgRs0Va8/ytWc3' \
      'AJ+121Q1Ss9U8vD08K5+wg1PVYyNa2YGBpVJbt2ZSt8dvuciWZujFDTzgLvR' \
      'r6w17kg6+jkiwJyz2ZIL6ytyiUE1oJzsbslIZN3yGHEcmXZZ8Xz5q8fzrLUV' \
      'mRx1kX6FE2QzRe4+6Q+qNeI8Ct7dj7JBBdbK2Jq+6A==',
      'https://contoso.com/wopi/files/Dy07US/uXVeOMwgyEqGqeVNnyOoaR' \
      'xR+es2atR08tZPMatf0gf0?access_token=7DHGrfxYtgXxfaXF%2benHF3' \
      'PTGMrgNlYktkbQB8q%2fn2aQwzYQ6qTmqNJRnJm5QIMXS7WbIxMy0LXaova2' \
      'h687Md4%2bNTazty3P7HD3j5q9anbCuLsUJHtSXfKANUetLyAjFWq6egtMZJ' \
      'SHzDajO0EaHTeA9M7zJg1j69dEMoLmIbxP03kwAvBrdVQmjFdFryKw'
    )
  end

  test 'Invalid proof key2.' do
    assert_not @discovery.verify_proof(
      'itKqYThsIRPrrctbu%2bh7%2fMcYvNZiVKc5Un50ZqjKtvhVwz0XcObcEVm5' \
      'rghR4PmrUG0P28QnQTYrcQ65%2bLtrIfbTBferY4zhPKt9qKaf6HKEyRU7ut' \
      'szLoIG7P7XIhmdTo0RftsCAO3gLp4ZqZiQi4icNS6mMGYboNZ1pHaNCRmR31' \
      'oZjmqWgcknWow8',
      635655897692506269,
      'Bu+myEy45g0hyKJycD7BYoDH+s10yvuH79Iq3OLz4w/o7gT8orKRrZ4KggJU' \
      'WMzRPPSgg+CqEf6zdNm6kFrxf/zXCXTqa/bEzmJPNBby+r0jlyz2KFsOkxJ/' \
      'mzVMKJltG0le56NJim21ZU4AwN0KiB6TZ56ruu/ma014proZWJt/H0qye/pN' \
      'z5ZyYdyc1khgzKf/8o6sCgh6+VEZx93BjAUyMJr6OS9nYq1B8XGei/sE4xdg' \
      'brIGW0Jwjl2hxqBQTn1VL0jyljbjuG+vy83QaeBSB4TGLljHZFgYp6ARCX7v' \
      '3NHO0MicJtTpLdpsB9dlLkbms/BcJd1gK7m5dDJK1A==',
      'CDU9l+cyr82vrUnyhdTh1P4jDwL82c//XrTWU/rPeTyB9Ko6z2aNCs893GEB' \
      '3jICY7mDZ4t0sA5z/lpN83UyfH1uVqnEB92zCQsJTkXMdNG9dsK64G6RxIVb' \
      'mhJkV5xiJvERCRnJJTcQg4ymeXQ3cuXAcN9XhStK8FCxBhxGMJsmlY2tahxd' \
      'TEIHXHVagvdyB1UY0V1rv+OAOnCGaTs0yyBA0Mo5nmTSNF8VnYmqsmbXyyDP' \
      'JJTsqallyJPxvdrLPeiBq1JHMr3b8dgel1jfweDR4mD9pHn3O9eaHN8b6xlL' \
      'c+dIpwvcflzyhhEL5JKEUtO6EKbfakZTUeS86BuBZA==',
      'https://contoso.com/wopi/files/6XZhdjvt6/cdJvXdBI1bdlIkhIjJP' \
      'nb9HgWzZX7V2d8?access_token=itKqYThsIRPrrctbu%2bh7%2fMcYvNZi' \
      'VKc5Un50ZqjKtvhVwz0XcObcEVm5rghR4PmrUG0P28QnQTYrcQ65%2bLtrIf' \
      'bTBferY4zhPKt9qKaf6HKEyRU7utszLoIG7P7XIhmdTo0RftsCAO3gLp4ZqZ' \
      'iQi4icNS6mMGYboNZ1pHaNCRmR31oZjmqWgcknWow8'
    )
  end
end
