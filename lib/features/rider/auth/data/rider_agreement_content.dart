/// The rider terms-of-use agreement shown on the signup wizard's terms
/// screen, authored as HTML and rendered with `flutter_html`.
///
/// Segregated into its own class so the legal copy and its version tag can
/// be swapped (e.g. for a CMS/backend-fetched version) without touching the
/// screen that renders it.
abstract final class RiderAgreementContent {
  /// Bumped whenever [html]'s substance changes; sent to
  /// `POST /rider/me/agreement` as `terms_version`.
  static const String version = '2026.09-10pct';

  static const String html = '''
<h2>Dispatch Rider Terms of Use Agreement (10% Commission)</h2>

<p>This Dispatch Rider Terms of Use Agreement (&ldquo;Agreement&rdquo;) is entered into between BagyesRUSH Delivery (&ldquo;BagyesRUSH&rdquo;, &ldquo;we&rdquo;, &ldquo;our&rdquo;, or &ldquo;the Company&rdquo;) and the individual dispatch rider (&ldquo;Rider&rdquo;, &ldquo;you&rdquo;, or &ldquo;your&rdquo;) who signs up to accept delivery orders through the BagyesRUSH mobile application (&ldquo;App&rdquo;).</p>

<p>By registering as a dispatch rider and using the BagyesRUSH App, you agree to the terms and conditions set out below.</p>

<h3>1. Independent Contractor Status</h3>
<p>1.1 You acknowledge that you are an independent contractor and not an employee, partner, agent, or representative of BagyesRUSH.</p>
<p>1.2 You are solely responsible for your motorcycle, bicycle, vehicle, smartphone, fuel, data, safety equipment, insurance, and all operational costs.</p>

<h3>2. Eligibility Requirements</h3>
<p>You confirm that you:</p>
<ol type="a">
  <li>Are at least 18 years old;</li>
  <li>Possess a valid government ID;</li>
  <li>Own or have legal access to a roadworthy vehicle;</li>
  <li>Hold a valid rider&rsquo;s license (where required by law);</li>
  <li>Comply with all traffic, safety, and operational regulations.</li>
</ol>

<h3>3. Commission and Payments</h3>
<p>3.1 BagyesRUSH charges a 10% commission on each successful delivery order completed through the App.</p>
<p>3.2 The rider receives 90% of the delivery fee, deposited into their designated mobile money wallet or bank account.</p>
<p>3.3 Commissions may be deducted automatically before payout.</p>
<p>3.4 Riders are responsible for filing and paying their own taxes or statutory fees.</p>

<h3>4. Use of the App</h3>
<p>4.1 You agree to use the App responsibly and only for legitimate delivery services.</p>
<p>4.2 You must not manipulate pricing, orders, or system functions.</p>
<p>4.3 You must complete accepted orders safely, respectfully, and professionally.</p>

<h3>5. Conduct and Service Standards</h3>
<p>Riders must:</p>
<ol type="a">
  <li>Treat all customers professionally and respectfully;</li>
  <li>Handle packages with care and deliver them on time;</li>
  <li>Keep customer information confidential;</li>
  <li>Avoid alcohol, drugs, or misconduct while working;</li>
  <li>Report damaged, lost, or disputed deliveries immediately.</li>
</ol>

<h3>6. Rider Responsibilities</h3>
<p>6.1 You are responsible for confirming pickup and drop-off details.</p>
<p>6.2 You may be held liable for negligence resulting in loss or damage.</p>
<p>6.3 You must maintain your vehicle in safe, legal, and roadworthy condition.</p>

<h3>7. Suspension or Termination</h3>
<p>BagyesRUSH may suspend or terminate your account for:</p>
<ol type="a">
  <li>Fraud, theft, or dishonest conduct;</li>
  <li>Unsafe riding or customer complaints;</li>
  <li>Repeated cancellations or order refusal trends;</li>
  <li>Any violation of this Agreement.</li>
</ol>

<h3>8. Limitation of Liability</h3>
<p>BagyesRUSH is not responsible for:</p>
<ol type="a">
  <li>Accidents, injuries, or damages during deliveries;</li>
  <li>Loss, theft, or malfunction of your equipment;</li>
  <li>Network or system disruptions beyond our control.</li>
</ol>
<p>You assume all risks associated with performing delivery services.</p>

<h3>9. Data and Privacy</h3>
<p>You consent to BagyesRUSH collecting and using your information for operational, security, and compliance purposes in accordance with our Privacy Policy.</p>

<h3>10. Amendments</h3>
<p>BagyesRUSH may modify these terms at any time. Continued use of the App after notification constitutes acceptance of revised terms.</p>

<h3>11. Governing Law</h3>
<p>This Agreement is governed by the laws of the jurisdiction in which BagyesRUSH operates.</p>

<h3>12. Acceptance</h3>
<p>By clicking &ldquo;Accept&rdquo; or using the BagyesRUSH App as a dispatch rider, you agree that you have read, understood, and accepted these terms.</p>
''';
}
