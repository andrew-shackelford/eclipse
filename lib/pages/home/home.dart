import 'package:flutter/material.dart';
import '../../components/link.dart';
import '../../utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Quick links',
                style: TextStyle(fontSize: 24),
              ),
              if (usingMockEclipseTime)
                const Text.rich(TextSpan(
                    text: '***Using mock eclipse date of 4/6 instead of 4/8***',
                    style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              Text(zuluString),
              const Text('The eclipse is from 1915Z to 1930Z,'),
              const Text('or 3:15 PM to 3:30 PM.'),
              const ClickableLink(
                  text: '1. Google Doc plan',
                  url:
                      'https://docs.google.com/document/d/1pwCCLExf3mCLNA2fC2w2OMp5OEQbjcwcKvwL3CEPEVI/edit#heading=h.xv7i91xrwk24'),
              const ClickableLink(
                  text: '2. Google Map with viewing locations',
                  url:
                      'https://www.google.com/maps/d/u/0/edit?mid=1iOy0QAcifkMBqyuvncVQxvWaomQ9E58&ll=11.052347403684646%2C-89.7628755&z=3'),
              const ClickableLink(
                  text: '3. NYTimes Cloud map',
                  url:
                      'https://www.nytimes.com/interactive/2024/science/solar-eclipse-cloud-cover-forecast-map.html?ugrp=m&unlocked_article_code=1.h00.TF0c.LYg62k9fVKOl&smid=url-share'),
              const ClickableLink(
                  text: '4. GOES satellite images and animations',
                  url:
                      'https://www.star.nesdis.noaa.gov/GOES/sector_band.php?sat=G16&sector=ne&band=DayNightCloudMicroCombo&length=48&dim=1'),
              const ClickableLink(
                  text: '5. Windy.com cloud forecast predictions',
                  url:
                      'https://www.windy.com/-Clouds-clouds?clouds,2024040821,43.237,-75.081,7'),
              const ClickableLink(
                  text: '6. Satellite w/ roads for East NY & VT',
                  url:
                      'https://weather.cod.edu/satrad/?parms=local-Vermont-truecolor-200-0-100-1&checked=usstrd-ushw-usint-map&colorbar=undefined'),
              const ClickableLink(
                  text: '7. Satellite w/ roads for West NY',
                  url:
                      'https://weather.cod.edu/satrad/?parms=local-LakeOntario-truecolor-200-0-100-1&checked=usstrd-ushw-usint-map&colorbar=undefined'),
              const ClickableLink(
                  text: '8. Satellite w/ roads for Northeast region',
                  url:
                      'https://weather.cod.edu/satrad/?parms=subregional-New_England-truecolor-200-0-100-1&checked=usstrd-ushw-usint-map&colorbar=undefined'),
              const ClickableLink(
                  text: '9. Satellite forecast models',
                  url: 'https://weather.cod.edu/forecast/'),
              const ClickableLink(
                  text: '10. Eclipsophile weather',
                  url: 'https://eclipsophile.com/eclipse-day-weather/'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                    'Notes:\n4. Live satellite animation\n5. Switch between forecast models\n6-9. Live satellite + roads & zoom in\n(probably best tool, but best viewed on laptop).'),
              )
            ],
          )),
    ));
  }
}
