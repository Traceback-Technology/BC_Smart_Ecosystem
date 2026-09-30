import 'package:flutter/material.dart';

import '../models/app_session.dart';

class StudentNameScreen
    extends StatefulWidget {
  const StudentNameScreen({
    super.key,
  });

  @override
  State<StudentNameScreen>
      createState() =>
          _StudentNameScreenState();
}

class _StudentNameScreenState
    extends State<StudentNameScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _firstNameController =
      TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    super.dispose();
  }

  String _formatFirstName(
    String value,
  ) {
    final name = value.trim();

    if (name.isEmpty) {
      return name;
    }

    return '${name[0].toUpperCase()}'
        '${name.substring(1)}';
  }

  void _continue() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final firstName =
        _formatFirstName(
      _firstNameController.text,
    );

    Navigator.of(context)
        .pop<AppSession>(
      AppSession.student(
        firstName: firstName,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Access',
        ),
      ),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 70,
                      color:
                          scheme.primary,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      'Welcome, Student',
                      textAlign:
                          TextAlign.center,
                      style:
                          Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Microsoft sign-in will be added later. '
                      'For now, enter your first name.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: scheme
                            .onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    TextFormField(
                      controller:
                          _firstNameController,
                      autofocus: true,
                      textCapitalization:
                          TextCapitalization
                              .words,
                      textInputAction:
                          TextInputAction
                              .done,
                      onFieldSubmitted:
                          (_) =>
                              _continue(),
                      validator:
                          (value) {
                        final name =
                            value
                                    ?.trim() ??
                                '';

                        if (name
                            .isEmpty) {
                          return 'Please enter your first name.';
                        }

                        if (name.length <
                            2) {
                          return 'Please enter a valid first name.';
                        }

                        return null;
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'First name',
                        hintText:
                            'e.g. Alex',
                        prefixIcon:
                            Icon(
                          Icons
                              .person_outline,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    FilledButton.icon(
                      onPressed:
                          _continue,
                      icon: const Icon(
                        Icons
                            .arrow_forward,
                      ),
                      label: const Text(
                        'Continue to Home',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}